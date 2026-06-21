<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Compra;
use App\Models\CompraDetalle;
use App\Models\CuentaPorPagar;
use App\Models\PagoCompra;
use App\Models\Producto;
use App\Services\ContabilidadService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Exception;

class CompraController extends Controller
{
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

    public function store(Request $request)
    {
        $validated = $request->validate([
            'proveedor_id' => 'required|exists:proveedores,id',
            'numero_factura_proveedor' => 'required|string',
            'ncf' => 'nullable|string',
            'fecha_compra' => 'required|date',
            'fecha_vencimiento' => 'nullable|date',
            'tipo_compra' => 'required|in:CONTADO,CREDITO',
            'notas' => 'nullable|string',
            'detalles' => 'required|array|min:1',
            'detalles.*.producto_id' => 'nullable|exists:productos,id',
            'detalles.*.descripcion' => 'nullable|string',
            'detalles.*.cantidad' => 'required|numeric|min:0.01',
            'detalles.*.costo_unitario' => 'required|numeric|min:0',
            'detalles.*.impuesto_monto' => 'required|numeric|min:0',
        ]);

        DB::beginTransaction();
        try {
            $subtotal = 0;
            $impuestos = 0;
            $total = 0;

            foreach ($validated['detalles'] as &$d) {
                $d_subtotal = $d['cantidad'] * $d['costo_unitario'];
                $d['subtotal'] = $d_subtotal;
                $d['total'] = $d_subtotal + $d['impuesto_monto'];

                $subtotal += $d['subtotal'];
                $impuestos += $d['impuesto_monto'];
                $total += $d['total'];
            }

            // Crear Compra
            $compra = Compra::create([
                'proveedor_id' => $validated['proveedor_id'],
                'numero_factura_proveedor' => $validated['numero_factura_proveedor'],
                'ncf' => $validated['ncf'] ?? null,
                'fecha_compra' => $validated['fecha_compra'],
                'fecha_vencimiento' => $validated['fecha_vencimiento'] ?? null,
                'tipo_compra' => $validated['tipo_compra'],
                'subtotal' => $subtotal,
                'impuestos' => $impuestos,
                'total' => $total,
                'estado' => $validated['tipo_compra'] === 'CONTADO' ? 'PAGADA' : 'PENDIENTE',
                'usuario_id' => auth()->id() ?? 1, // fallback to 1 if testing
                'notas' => $validated['notas'] ?? null,
            ]);

            // Guardar Detalles y actualizar costo de productos
            foreach ($validated['detalles'] as $d) {
                CompraDetalle::create([
                    'compra_id' => $compra->id,
                    'producto_id' => $d['producto_id'] ?? null,
                    'descripcion' => $d['descripcion'] ?? null,
                    'cantidad' => $d['cantidad'],
                    'costo_unitario' => $d['costo_unitario'],
                    'subtotal' => $d['subtotal'],
                    'impuesto_monto' => $d['impuesto_monto'],
                    'total' => $d['total'],
                ]);

                if (!empty($d['producto_id'])) {
                    $producto = Producto::find($d['producto_id']);
                    if ($producto) {
                        // El usuario solicitó no actualizar el costo del producto en el catálogo automáticamente
                        // $producto->update(['ultimo_costo' => $d['costo_unitario']]);
                        
                        if ($producto->maneja_inventario) {
                            $producto->increment('stock_actual', $d['cantidad']);
                        }
                    }
                }
            }

            // Registro Contable de la Compra (Aplica a Contado y Crédito)
            // Usa 'compra_inventario' que asume que va a inventario/gasto y genera la CxP
            $asientoCompra = $this->contabilidadService->registrarAsientoAuto(
                'compra_inventario',
                $subtotal,
                $impuestos,
                $total,
                "COMPRA-{$compra->id}",
                "Compra a proveedor Fac: {$compra->numero_factura_proveedor}",
                auth()->id() ?? 1
            );

            if ($asientoCompra) {
                $compra->update(['asiento_id' => $asientoCompra->id]);
            }

            // Manejo de Cuentas por Pagar (CxP)
            if ($validated['tipo_compra'] === 'CREDITO') {
                CuentaPorPagar::create([
                    'proveedor_id' => $compra->proveedor_id,
                    'compra_id' => $compra->id,
                    'monto_original' => $total,
                    'balance_pendiente' => $total,
                    'fecha_vencimiento' => $compra->fecha_vencimiento ?? $compra->fecha_compra,
                    'estado' => 'PENDIENTE',
                ]);
            } else {
                // Es CONTADO, se crea y se paga inmediatamente
                $cxp = CuentaPorPagar::create([
                    'proveedor_id' => $compra->proveedor_id,
                    'compra_id' => $compra->id,
                    'monto_original' => $total,
                    'balance_pendiente' => 0,
                    'fecha_vencimiento' => $compra->fecha_compra,
                    'estado' => 'PAGADA',
                ]);

                // Registrar Pago
                $pago = PagoCompra::create([
                    'cxp_id' => $cxp->id,
                    'monto_pagado' => $total,
                    'fecha_pago' => $compra->fecha_compra,
                    'metodo_pago' => 'EFECTIVO', // Por defecto efectivo si es contado
                    'cuenta_origen_id' => 1, // Deberia venir de la config, pondremos 1 provisoriamente
                    'usuario_id' => auth()->id() ?? 1,
                ]);

                // Asiento Contable del Pago
                $asientoPago = $this->contabilidadService->registrarAsientoAuto(
                    'pago_compra',
                    0, 0, $total,
                    "PAGO-COMPRA-{$compra->id}",
                    "Pago de contado por compra Fac: {$compra->numero_factura_proveedor}",
                    auth()->id() ?? 1,
                    ['pago_compra_efectivo_haber' => 1] // <- INYECCIÓN DINÁMICA DE LA CUENTA ORIGEN
                );

                if ($asientoPago) {
                    $pago->update(['asiento_id' => $asientoPago->id]);
                }
            }

            DB::commit();
            return response()->json($compra->load('detalles'), 201);

        } catch (Exception $e) {
            DB::rollBack();
            return response()->json(['error' => 'Error al registrar la compra: ' . $e->getMessage()], 500);
        }
    }

    public function show($id)
    {
        $compra = Compra::with(['proveedor', 'detalles.producto', 'usuario', 'cuentaPorPagar', 'asiento'])->findOrFail($id);
        return response()->json($compra);
    }
}
