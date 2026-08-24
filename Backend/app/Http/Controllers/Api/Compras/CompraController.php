<?php

namespace App\Http\Controllers\Api\Compras;

use App\Http\Controllers\Controller;
use App\Models\Compra;
use App\Models\CompraDetalle;
use App\Models\CuentaPorPagar;
use App\Models\PagoCompra;
use App\Models\Producto;
use App\Models\Proveedor;
use App\Services\ContabilidadService;
use App\Traits\HasIdempotency;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Exception;
use App\Models\ConfiguracionContable;
use App\Models\MetodoPago;
use App\Services\BankService;

class CompraController extends Controller
{
    use HasIdempotency;

    protected $contabilidadService;

    public function __construct(ContabilidadService $contabilidadService)
    {
        $this->contabilidadService = $contabilidadService;
    }

    public function index(Request $request)
    {
        $query = Compra::with(['proveedor', 'detalles.producto', 'usuario', 'cuentaPorPagar'])
            ->orderBy('id', 'desc');

        if ($request->filled('fecha_desde')) {
            $query->where('fecha_compra', '>=', $request->fecha_desde);
        }

        if ($request->filled('fecha_hasta')) {
            $query->where('fecha_compra', '<=', $request->fecha_hasta . ' 23:59:59');
        }

        $compras = $query->get();
        return response()->json($compras);
    }

    public function store(Request $request) {
        $request->validate([
            'proveedor_id'                  => 'required|exists:proveedores,id',
            'numero_factura_proveedor'      => 'required|string',
            'ncf'                           => 'nullable|string',
            'fecha_compra'                  => 'required|date',
            'fecha_vencimiento'             => 'nullable|date',
            'tipo_compra'                   => 'required|in:CONTADO,CREDITO',
            'metodo_pago_id'                => 'nullable|exists:metodo_pagos,id',
            'referencia_pago'               => 'nullable|string',
            'notas'                         => 'nullable|string',
            'idempotency_key'               => 'nullable|string|max:36',
            'detalles'                      => 'required|array|min:1',
            'detalles.*.producto_id'        => 'nullable|exists:productos,id',
            'detalles.*.descripcion'        => 'nullable|string',
            'detalles.*.cantidad'           => 'required|numeric|min:0.01',
            'detalles.*.costo_unitario'     => 'required|numeric|min:0',
            'detalles.*.impuesto_monto'     => 'required|numeric|min:0',
        ]);

        // ── IDEMPOTENCIA (tabla dedicada) ─────────────────────────────────────
        // Verifica si el key+endpoint ya fue procesado:
        //   • completed  → devuelve la respuesta cacheada (sin tocar la BD)
        //   • processing → 409 Conflict (request concurrente en curso)
        //   • failed     → permite reintento
        //   • nuevo      → registra 'processing' y retorna null (proceder)
        $cached = $this->checkIdempotency($request, 'compra.store');
        if ($cached) return $cached;
        // ─────────────────────────────────────────────────────────────────────

        DB::beginTransaction();
        try {
            $subtotal  = 0;
            $impuestos = 0;
            $total     = 0;

            $detalles = $request->input('detalles');
            foreach ($detalles as &$d) {
                $d_subtotal    = $d['cantidad'] * $d['costo_unitario'];
                $d['subtotal'] = $d_subtotal;
                $d['total']    = $d_subtotal + $d['impuesto_monto'];

                $subtotal  += $d['subtotal'];
                $impuestos += $d['impuesto_monto'];
                $total     += $d['total'];
            }
            unset($d);

            // Verificar si el proveedor es informal para generar E41 y aplicar retención
            $proveedor = Proveedor::findOrFail($request->proveedor_id);
            $esInformal = (bool) $proveedor->es_informal;
            $ncfFinal = $request->ncf;

            if ($esInformal) {
                // Buscar secuencia E41
                $sec = DB::table('ncf_secuencias')->where('tipo', '41')->lockForUpdate()->first();
                if ($sec) {
                    $nuevo = $sec->actual + 1;
                    DB::table('ncf_secuencias')->where('id', $sec->id)->update(['actual' => $nuevo]);
                    // E41 requiere 10 digitos de secuencia para completar 13 chars (E41 + 10)
                    $ncfFinal = 'E41' . str_pad($nuevo, 10, '0', STR_PAD_LEFT);
                }
            }

            // Crear Compra
            $compra = Compra::create([
                'proveedor_id'              => $request->proveedor_id,
                'numero_factura_proveedor'  => $request->numero_factura_proveedor,
                'ncf'                       => $ncfFinal,
                'fecha_compra'              => $request->fecha_compra,
                'fecha_vencimiento'         => $request->fecha_vencimiento,
                'tipo_compra'               => $request->tipo_compra,
                'subtotal'                  => $subtotal,
                'impuestos'                 => $impuestos,
                'total'                     => $total,
                'estado'                    => $request->tipo_compra === 'CONTADO' ? 'PAGADA' : 'PENDIENTE',
                'usuario_id'                => auth()->id() ?? 1,
                'notas'                     => $request->notas,
            ]);

            // Guardar Detalles y actualizar stock de productos
            foreach ($detalles as $d) {
                CompraDetalle::create([
                    'compra_id'      => $compra->id,
                    'producto_id'    => $d['producto_id'] ?? null,
                    'descripcion'    => $d['descripcion'] ?? null,
                    'cuenta_contable_id' => $d['cuenta_contable_id'] ?? null,
                    'cantidad'       => $d['cantidad'],
                    'costo_unitario' => $d['costo_unitario'],
                    'subtotal'       => $d['subtotal'],
                    'impuesto_monto' => $d['impuesto_monto'],
                    'total'          => $d['total'],
                ]);

                if (!empty($d['producto_id'])) {
                    $producto = Producto::find($d['producto_id']);
                    if ($producto) {
                        if ($producto->maneja_inventario) {
                            $stockAnterior = $producto->stock_actual;
                            $nuevoStock = $stockAnterior + $d['cantidad'];
                            
                            $costoAnterior = $producto->costo;
                            $valorActual = $stockAnterior * $costoAnterior;
                            $valorNuevo = $d['cantidad'] * $d['costo_unitario'];
                            
                            $nuevoCosto = ($nuevoStock > 0) ? (($valorActual + $valorNuevo) / $nuevoStock) : $d['costo_unitario'];

                            $producto->update([
                                'costo' => round($nuevoCosto, 4)
                            ]);
                            
                            $producto->increment('stock_actual', $d['cantidad']);
                        }
                    }
                }
            }

            // Registro Contable de la Compra (Aplica a Contado y Crédito)
            // Se inyecta 'es_informal' para que CompraInventarioStrategy retenga el ITBIS si aplica
            $asientoCompra = $this->contabilidadService->registrarAsientoAuto(
                'compra_inventario',
                $subtotal,
                $impuestos,
                $total,
                "COMPRA-{$compra->id}",
                "Compra a proveedor Fac: {$compra->numero_factura_proveedor}",
                auth()->id() ?? 1,
                ['es_informal' => $esInformal, 'detalles' => $detalles]
            );

            if ($asientoCompra) {
                $compra->update(['asiento_id' => $asientoCompra->id]);
            }

            // Manejo de Cuentas por Pagar (CxP)
            // Si es informal, al proveedor NO se le paga el ITBIS (se le retiene)
            $montoAlProveedor = $esInformal ? $subtotal : $total;

            if ($request->tipo_compra === 'CREDITO') {
                CuentaPorPagar::create([
                    'proveedor_id'     => $compra->proveedor_id,
                    'compra_id'        => $compra->id,
                    'monto_original'   => $montoAlProveedor,
                    'balance_pendiente'=> $montoAlProveedor,
                    'fecha_vencimiento'=> $compra->fecha_vencimiento ?? $compra->fecha_compra,
                    'estado'           => 'PENDIENTE',
                ]);
            } else {
                // CONTADO: crear CxP ya saldada y registrar el pago inmediatamente
                $cxp = CuentaPorPagar::create([
                    'proveedor_id'     => $compra->proveedor_id,
                    'compra_id'        => $compra->id,
                    'monto_original'   => $montoAlProveedor,
                    'balance_pendiente'=> 0,
                    'fecha_vencimiento'=> $compra->fecha_compra,
                    'estado'           => 'PAGADA',
                ]);

                $metodoPagoId = $request->metodo_pago_id;
                $configCuentaEfectivo = ConfiguracionContable::where('clave', 'pago_compra_efectivo_haber')->value('cuenta_id') ?? 1;
                $bancoIdAfectado = null;
                $nombreMetodo = 'EFECTIVO';
                $referenciaPago = $request->referencia_pago;

                $customConfigsPago = [];

                if ($metodoPagoId) {
                    $metodo = MetodoPago::find($metodoPagoId);
                    if ($metodo) {
                        $nombreMetodo = $metodo->nombre;
                        if ($metodo->catalogo_cuenta_id) {
                            $configCuentaEfectivo = $metodo->catalogo_cuenta_id;
                            $customConfigsPago['pago_compra_efectivo_haber'] = $metodo->catalogo_cuenta_id;
                        }
                        if ($metodo->bank_account_id) {
                            $bancoIdAfectado = $metodo->bank_account_id;
                        }
                    }
                }

                $pago = PagoCompra::create([
                    'cxp_id'          => $cxp->id,
                    'monto_pagado'    => $montoAlProveedor,
                    'fecha_pago'      => $compra->fecha_compra,
                    'metodo_pago_id'  => $metodoPagoId,
                    'referencia'      => $referenciaPago,
                    'cuenta_origen_id'=> $configCuentaEfectivo,
                    'usuario_id'      => auth()->id() ?? 1,
                ]);

                // Asiento Contable del Pago de Contado
                $asientoPago = $this->contabilidadService->registrarAsientoAuto(
                    'pago_compra',
                    0, 0, $montoAlProveedor,
                    "PAGO-COMPRA-{$compra->id}",
                    "Pago de contado por compra Fac: {$compra->numero_factura_proveedor}",
                    auth()->id() ?? 1,
                    $customConfigsPago
                );

                if ($asientoPago) {
                    $pago->update(['asiento_id' => $asientoPago->id]);
                }

                // 🏦 REGISTRAR TRANSACCIÓN BANCARIA (Si aplica)
                if ($bancoIdAfectado) {
                    $asientoId = $asientoPago ? $asientoPago->id : null;
                    app(BankService::class)->registrarTransaccion(
                        $bancoIdAfectado,
                        'withdrawal',
                        $montoAlProveedor,
                        $referenciaPago,
                        "Pago de Contado Compra Fac: {$compra->numero_factura_proveedor}",
                        $asientoId
                    );
                }
            }

            DB::commit();

            // ── GUARDAR RESPUESTA EN TABLA DE IDEMPOTENCIA ───────────────────
            // A partir de aquí cualquier reintento con el mismo key recibirá
            // este mismo JSON sin re-ejecutar ninguna transacción contable.
            $responseData = $compra->load(['detalles', 'cuentaPorPagar', 'asiento'])->toArray();
            return $this->saveIdempotency($request, 'compra.store', $responseData, 201);
            // ─────────────────────────────────────────────────────────────────

        } catch (Exception $e) {
            DB::rollBack();
            // Marcar el key como fallido para permitir reintento
            $this->failIdempotency($request, 'compra.store');
            return response()->json(['error' => 'Error al registrar la compra: ' . $e->getMessage()], 500);
        }
    }

    public function show($id)
    {
        $compra = Compra::with(['proveedor', 'detalles.producto', 'usuario', 'cuentaPorPagar', 'asiento'])->findOrFail($id);
        return response()->json($compra);
    }
}

