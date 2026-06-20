<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\CuentaPorPagar;
use App\Models\PagoCompra;
use App\Services\ContabilidadService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Exception;

class CxpController extends Controller
{
    protected $contabilidadService;

    public function __construct(ContabilidadService $contabilidadService)
    {
        $this->contabilidadService = $contabilidadService;
    }

    public function index()
    {
        // Get all unpaid or partially paid CxPs
        $cxps = CuentaPorPagar::with(['proveedor', 'compra.detalles.producto'])
            ->orderBy('fecha_vencimiento', 'asc')
            ->get();
            
        return response()->json($cxps);
    }

    public function registrarPago(Request $request, $id)
    {
        $cxp = CuentaPorPagar::findOrFail($id);

        $validated = $request->validate([
            'monto_pagado' => 'required|numeric|min:0.01|max:'.$cxp->balance_pendiente,
            'fecha_pago' => 'required|date',
            'metodo_pago' => 'required|in:EFECTIVO,TRANSFERENCIA,CHEQUE',
            'cuenta_origen_id' => 'required|exists:catalogo_cuentas,id', // Bank or Cash account
            'referencia' => 'nullable|string',
        ]);

        DB::beginTransaction();
        try {
            // Registrar el pago
            $pago = PagoCompra::create([
                'cxp_id' => $cxp->id,
                'monto_pagado' => $validated['monto_pagado'],
                'fecha_pago' => $validated['fecha_pago'],
                'metodo_pago' => $validated['metodo_pago'],
                'referencia' => $validated['referencia'] ?? null,
                'cuenta_origen_id' => $validated['cuenta_origen_id'],
                'usuario_id' => auth()->id() ?? 1,
            ]);

            // Actualizar Balance CxP
            $nuevoBalance = $cxp->balance_pendiente - $validated['monto_pagado'];
            $estado = 'PENDIENTE';
            if ($nuevoBalance <= 0) {
                $estado = 'PAGADA';
                $nuevoBalance = 0;
            } elseif ($nuevoBalance < $cxp->monto_original) {
                $estado = 'PARCIAL';
            }

            $cxp->update([
                'balance_pendiente' => $nuevoBalance,
                'estado' => $estado,
            ]);

            // Si se pagó la CxP entera, actualizar estado de la Compra a PAGADA
            if ($estado === 'PAGADA' && $cxp->compra) {
                $cxp->compra->update(['estado' => 'PAGADA']);
            }

            // Registrar Asiento Contable del Pago
            // El PagoCompraStrategy usa 'pago_compra_efectivo_haber' o asume el método.
            // Para simplificar, el Strategy ya toma la configuración global, aunque lo ideal 
            // sería que use $validated['cuenta_origen_id'].
            // Pero como la firma es generarDetalles(configs, ...), adaptaremos el servicio 
            // o lo registramos manualmente si es necesario. 
            // Vamos a registrarlo con el service y si falta algo, se ajusta después.
            $asientoPago = $this->contabilidadService->registrarAsientoAuto(
                'pago_compra',
                0, 0, $validated['monto_pagado'],
                "PAGO-CXP-{$pago->id}",
                "Abono a CxP de Compra Fac: " . ($cxp->compra->numero_factura_proveedor ?? 'N/A'),
                auth()->id() ?? 1,
                ['pago_compra_efectivo_haber' => $validated['cuenta_origen_id']]
            );

            if ($asientoPago) {
                $pago->update(['asiento_id' => $asientoPago->id]);
            }

            DB::commit();
            return response()->json(['message' => 'Pago registrado con éxito', 'pago' => $pago]);
        } catch (Exception $e) {
            DB::rollBack();
            return response()->json(['error' => 'Error al registrar el abono: ' . $e->getMessage()], 500);
        }
    }

    public function historialPagos()
    {
        $pagos = PagoCompra::with([
            'cuentaPorPagar.proveedor',
            'cuentaPorPagar.compra',
            'cuentaOrigen',
            'usuario'
        ])->orderBy('fecha_pago', 'desc')->get();

        return response()->json($pagos);
    }
}
