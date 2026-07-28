<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\PagoDgii;
use App\Models\CatalogoCuenta;
use App\Models\Compra;
use App\Models\Factura;
use App\Services\ContabilidadService;
use Illuminate\Support\Facades\DB;
use Exception;

class DgiiController extends Controller
{
    protected $contabilidadService;

    public function __construct(ContabilidadService $contabilidadService)
    {
        $this->contabilidadService = $contabilidadService;
    }

    public function getBalance()
    {
        // El balance de ITBIS POR PAGAR es el código 2.1.02
        $cuenta = CatalogoCuenta::where('codigo', '2.1.02')->first();
        if (!$cuenta) {
            return response()->json(['error' => 'No se encontró la cuenta 2.1.02 (ITBIS POR PAGAR)'], 404);
        }

        // Siendo cuenta de Pasivo (naturaleza crédito):
        // Balance = Suma Créditos - Suma Débitos
        $creditos = $cuenta->entradas()->sum('credito');
        $debitos = $cuenta->entradas()->sum('debito');
        
        $balance = $creditos - $debitos;

        return response()->json([
            'cuenta_id' => $cuenta->id,
            'codigo' => $cuenta->codigo,
            'nombre' => $cuenta->nombre,
            'balance' => $balance
        ]);
    }

    public function getPagos()
    {
        $pagos = PagoDgii::with(['cuentaOrigen', 'usuario'])->orderBy('fecha_pago', 'desc')->get();
        return response()->json($pagos);
    }

    public function registrarPago(Request $request)
    {
        $validated = $request->validate([
            'fecha_pago' => 'required|date',
            'monto_pagado' => 'required|numeric|min:0.01',
            'periodo_mes' => 'required|string|size:2',
            'periodo_anio' => 'required|string|size:4',
            'cuenta_origen_id' => 'required|exists:catalogo_cuentas,id',
            'referencia' => 'nullable|string',
        ]);

        DB::beginTransaction();
        try {
            // Guardar el registro de pago
            $pago = PagoDgii::create([
                'fecha_pago' => $validated['fecha_pago'],
                'monto_pagado' => $validated['monto_pagado'],
                'periodo_mes' => $validated['periodo_mes'],
                'periodo_anio' => $validated['periodo_anio'],
                'referencia' => $validated['referencia'] ?? null,
                'cuenta_origen_id' => $validated['cuenta_origen_id'],
                'usuario_id' => auth()->id() ?? 1,
            ]);

            // Crear el asiento contable inyectando temporalmente la cuenta_banco_haber en config
            // Para eso, le enviamos un flag al servicio si lo tuviéramos, o registramos
            // manual si la estrategia lo pide. La estrategia PagoDgiiStrategy lee
            // $configs['pago_dgii_banco_haber'].
            // Como no podemos modificar la config on the fly fácilmente desde aquí, 
            // crearemos el array config personalizado para este asiento:

            $configs = \App\Models\ConfiguracionContable::pluck('cuenta_id', 'clave')->toArray();
            $configs['pago_dgii_banco_haber'] = $validated['cuenta_origen_id']; // inyección manual de cuenta elegida

            $asiento = \App\Models\AsientoContable::create([
                'fecha' => $validated['fecha_pago'],
                'referencia' => "DGII-{$pago->id}",
                'descripcion' => "Pago de Impuestos DGII período {$validated['periodo_mes']}/{$validated['periodo_anio']} - Ref: " . ($validated['referencia'] ?? 'N/A'),
                'usuario_id' => auth()->id() ?? 1,
            ]);

            // Generar detalles del asiento
            $strategyFactory = new \App\Accounting\AsientoStrategyFactory();
            $strategy = $strategyFactory->make('pago_dgii');
            
            // $subtotal=0, $itbis=0, $total=$monto_pagado
            $detalles = $strategy->generarDetalles($configs, 0, 0, $validated['monto_pagado']);

            foreach ($detalles as $detalle) {
                $asiento->detalles()->create($detalle);
            }

            // Validar cuadre
            $totalDebito = round($asiento->detalles()->sum('debito'), 2);
            $totalCredito = round($asiento->detalles()->sum('credito'), 2);

            if ($totalDebito !== $totalCredito) {
                throw new Exception("El asiento contable no cuadra (Débitos: {$totalDebito}, Créditos: {$totalCredito})");
            }

            // Actualizar pago con el asiento generado
            $pago->update(['asiento_id' => $asiento->id]);

            DB::commit();
            return response()->json(['message' => 'Pago a DGII registrado con éxito', 'pago' => $pago]);
        } catch (Exception $e) {
            DB::rollBack();
            return response()->json(['error' => 'Error al registrar pago a DGII: ' . $e->getMessage()], 500);
        }
    }

    public function exportar606(Request $request)
    {
        $mes = $request->query('mes');
        $anio = $request->query('anio');

        if (!$mes || !$anio) {
            return response()->json(['error' => 'Se requiere el mes y año (ej. ?mes=04&anio=2026)'], 400);
        }

        $compras = Compra::with('proveedor')
            ->whereMonth('fecha_compra', $mes)
            ->whereYear('fecha_compra', $anio)
            ->where('estado', '!=', 'ANULADA')
            ->get();

        $lineas = [];
        // Formato 606 (Ejemplo estándar de columnas)
        // RNC o Cédula, Tipo Bien, NCF, NCF o Documento Modificado, Fecha Comprobante (AAAAMMDD)...
        foreach ($compras as $compra) {
            $rnc = $compra->proveedor->rnc ?? '';
            $ncf = $compra->ncf ?? '';
            $fecha = \Carbon\Carbon::parse($compra->fecha_compra)->format('Ymd');
            $subtotal = number_format($compra->subtotal, 2, '.', '');
            $itbis = number_format($compra->impuestos, 2, '.', '');
            
            // Tipo de bien = 01 (Gastos de personal), 02 (Trabajos)... o genérico
            // Para simplificar generaremos una línea CSV básica como ejemplo
            $lineas[] = implode("|", [$rnc, '02', $ncf, '', $fecha, $subtotal, $itbis]);
        }

        $content = implode("\n", $lineas);
        
        return response($content)
            ->header('Content-Type', 'text/plain')
            ->header('Content-Disposition', "attachment; filename=\"606_{$anio}{$mes}.txt\"");
    }

    public function preview606(Request $request)
    {
        $mes = $request->query('mes');
        $anio = $request->query('anio');

        if (!$mes || !$anio) {
            return response()->json(['error' => 'Se requiere el mes y año (ej. ?mes=04&anio=2026)'], 400);
        }

        $compras = Compra::with('proveedor')
            ->whereMonth('fecha_compra', $mes)
            ->whereYear('fecha_compra', $anio)
            ->where('estado', '!=', 'ANULADA')
            ->get();

        $datos = [];
        foreach ($compras as $compra) {
            $datos[] = [
                'rnc' => $compra->proveedor->rnc ?? '',
                'nombre' => $compra->proveedor->nombre ?? 'Desconocido',
                'ncf' => $compra->ncf ?? '',
                'fecha' => \Carbon\Carbon::parse($compra->fecha_compra)->format('Y/m/d'),
                'subtotal' => (float)$compra->subtotal,
                'itbis' => (float)$compra->impuestos,
                'total' => (float)$compra->total,
            ];
        }

        return response()->json($datos);
    }

    public function exportar607(Request $request)
    {
        $mes = $request->query('mes');
        $anio = $request->query('anio');

        if (!$mes || !$anio) {
            return response()->json(['error' => 'Se requiere el mes y año (ej. ?mes=04&anio=2026)'], 400);
        }

        $facturas = Factura::with('cliente')
            ->whereMonth('fecha_emision', $mes)
            ->whereYear('fecha_emision', $anio)
            ->where('estado', '!=', 'anulada')
            ->get();
            
        $notasCredito = \App\Models\NotaCredito::with('factura.cliente')
            ->whereMonth('created_at', $mes)
            ->whereYear('created_at', $anio)
            ->get();

        $lineas = [];
        foreach ($facturas as $factura) {
            $rnc = $factura->cliente->rnc ?? '';
            $ncf = $factura->ncf ?? '';
            $fecha = \Carbon\Carbon::parse($factura->fecha_emision)->format('Ymd');
            $subtotal = number_format($factura->subtotal, 2, '.', '');
            $itbis = number_format($factura->itbis, 2, '.', '');
            
            $lineas[] = implode("|", [$rnc, $ncf, '', $fecha, $subtotal, $itbis]);
        }

        foreach ($notasCredito as $nc) {
            $rnc = $nc->factura->cliente->rnc ?? '';
            $ncf = $nc->ncf ?? '';
            $ncfModificado = $nc->factura->ncf ?? '';
            $fecha = \Carbon\Carbon::parse($nc->created_at)->format('Ymd');
            $subtotal = number_format($nc->subtotal, 2, '.', '');
            $itbis = number_format($nc->itbis, 2, '.', '');
            
            $lineas[] = implode("|", [$rnc, $ncf, $ncfModificado, $fecha, $subtotal, $itbis]);
        }

        $content = implode("\n", $lineas);

        return response($content)
            ->header('Content-Type', 'text/plain')
            ->header('Content-Disposition', "attachment; filename=\"607_{$anio}{$mes}.txt\"");
    }

    public function preview607(Request $request)
    {
        $mes = $request->query('mes');
        $anio = $request->query('anio');

        if (!$mes || !$anio) {
            return response()->json(['error' => 'Se requiere el mes y año (ej. ?mes=04&anio=2026)'], 400);
        }

        $facturas = Factura::with('cliente')
            ->whereMonth('fecha_emision', $mes)
            ->whereYear('fecha_emision', $anio)
            ->where('estado', '!=', 'anulada')
            ->get();
            
        $notasCredito = \App\Models\NotaCredito::with('factura.cliente')
            ->whereMonth('created_at', $mes)
            ->whereYear('created_at', $anio)
            ->get();

        $datos = [];
        foreach ($facturas as $factura) {
            $datos[] = [
                'rnc' => $factura->cliente->rnc ?? '',
                'nombre' => $factura->cliente->nombre ?? 'Desconocido',
                'ncf' => $factura->ncf ?? '',
                'ncf_modificado' => '',
                'fecha' => \Carbon\Carbon::parse($factura->fecha_emision)->format('Y/m/d'),
                'subtotal' => (float)$factura->subtotal,
                'itbis' => (float)$factura->itbis,
                'total' => (float)$factura->total,
            ];
        }
        
        foreach ($notasCredito as $nc) {
            $datos[] = [
                'rnc' => $nc->factura->cliente->rnc ?? '',
                'nombre' => $nc->factura->cliente->nombre ?? 'Desconocido',
                'ncf' => $nc->ncf ?? '',
                'ncf_modificado' => $nc->factura->ncf ?? '',
                'fecha' => \Carbon\Carbon::parse($nc->created_at)->format('Y/m/d'),
                'subtotal' => (float)$nc->subtotal,
                'itbis' => (float)$nc->itbis,
                'total' => (float)$nc->total,
            ];
        }

        return response()->json($datos);
    }
}
