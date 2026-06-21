<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\OrdenCompra;
use App\Models\OrdenCompraDetalle;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Validator;
use Barryvdh\DomPDF\Facade\Pdf;
use Exception;

class OrdenCompraController extends Controller
{
    public function store(Request $request)
    {
        DB::beginTransaction();

        try {
            $validator = Validator::make($request->all(), [
                'proveedor_id' => 'required|exists:proveedores,id',
                'fecha_emision' => 'required|date',
                'detalles' => 'required|array|min:1',
            ]);

            if ($validator->fails()) {
                return response()->json([
                    'message' => 'Error en la validación',
                    'errors' => $validator->errors(),
                    'status' => 400
                ], 400);
            }

            $detalles = $request->detalles;

            $subtotal = 0;
            $itbisTotal = 0;
            $descuentoTotal = 0;

            $detallesCalculados = [];

            foreach ($detalles as $item) {
                $calc = $this->calcularLinea($item);

                $subtotal += $calc['baseConDescuento'];
                $descuentoTotal += $calc['descuento'];
                $itbisTotal += $calc['itbis'];

                $detallesCalculados[] = [
                    'item' => $item,
                    'calc' => $calc
                ];
            }

            $total = $subtotal + $itbisTotal;

            // Generate unique Order Number
            $lastOrder = OrdenCompra::orderBy('id', 'desc')->first();
            $nextId = $lastOrder ? $lastOrder->id + 1 : 1;
            $numeroOrden = 'OC-' . str_pad($nextId, 6, '0', STR_PAD_LEFT);

            $fechaVencimiento = $request->fecha_vencimiento ?? date('Y-m-d', strtotime($request->fecha_emision . ' + 15 days'));

            $orden = OrdenCompra::create([
                'usuario_id' => auth()->id(),
                'proveedor_id' => $request->proveedor_id,
                'numero_orden' => $numeroOrden,
                'fecha' => $request->fecha_emision,
                'fecha_vencimiento' => $fechaVencimiento,
                'subtotal' => round($subtotal, 2),
                'descuento_total' => round($descuentoTotal, 2),
                'itbis' => round($itbisTotal, 2),
                'total' => round($total, 2),
                'estado' => 'BORRADOR',
                'notas' => $request->nota,
            ]);

            foreach ($detallesCalculados as $detalle) {
                $item = $detalle['item'];
                $calc = $detalle['calc'];

                OrdenCompraDetalle::create([
                    'orden_compra_id' => $orden->id,
                    'producto_id' => $item['producto_id'] ?? null,
                    'descripcion' => $item['descripcion'],
                    'cantidad' => $item['cantidad'],
                    'costo_esperado' => $item['precio'], // Using 'precio' from frontend to 'costo_esperado' in backend
                    'subtotal' => round($calc['baseConDescuento'], 2),
                    'itbis' => round($calc['itbis'], 2),
                    'total' => round($calc['total'], 2),
                ]);
            }

            DB::commit();

            return response()->json([
                'message' => 'Orden de compra creada correctamente',
                'status' => 201,
                'orden_compra_id' => $orden->id
            ], 201);

        } catch (\Exception $e) {
            DB::rollBack();

            return response()->json([
                'message' => 'Error al crear la orden de compra',
                'error' => $e->getMessage(),
                'status' => 500
            ], 500);
        }
    }

    private function calcularLinea($item)
    {
        $precio = floatval($item['precio']);
        $cantidad = floatval($item['cantidad']);
        
        $impuestoIncluido = isset($item['impuesto_incluido']) ? filter_var($item['impuesto_incluido'], FILTER_VALIDATE_BOOLEAN) : false;
        
        $tasaImpuesto = isset($item['tasa_impuesto']) ? floatval($item['tasa_impuesto']) / 100 : 0.18; 
        $descuentoPorcentaje = isset($item['descuento_porcentaje']) ? floatval($item['descuento_porcentaje']) / 100 : 0;

        $precioSinImpuesto = $precio;
        if ($impuestoIncluido && $tasaImpuesto > 0) {
            $precioSinImpuesto = $precio / (1 + $tasaImpuesto);
        }

        $baseTotal = $precioSinImpuesto * $cantidad;
        $montoDescuento = $baseTotal * $descuentoPorcentaje;
        $baseConDescuento = $baseTotal - $montoDescuento;

        $montoItbis = $baseConDescuento * $tasaImpuesto;
        $totalLinea = $baseConDescuento + $montoItbis;

        return [
            'precioBase' => $precioSinImpuesto,
            'baseTotal' => $baseTotal,
            'descuento' => $montoDescuento,
            'baseConDescuento' => $baseConDescuento,
            'itbis' => $montoItbis,
            'total' => $totalLinea
        ];
    }

    public function index(Request $request)
    {
        $query = OrdenCompra::with('proveedor', 'usuario')
            ->orderBy('fecha', 'desc');

        if ($request->filled('fecha_desde')) {
            $query->where('fecha', '>=', $request->fecha_desde);
        }

        if ($request->filled('fecha_hasta')) {
            $query->where('fecha', '<=', $request->fecha_hasta . ' 23:59:59');
        }

        if ($request->filled('proveedor_id')) {
            $query->where('proveedor_id', $request->proveedor_id);
        }

        if ($request->filled('estado')) {
            $query->where('estado', $request->estado);
        }

        $resumenQuery = clone $query;
        $totales = $resumenQuery->reorder()->selectRaw('
            COUNT(*) as cantidad_ordenes, 
            SUM(total) as total_monto
        ')->first();

        $ordenes = $query->paginate($request->per_page ?? 15);

        return response()->json([
            'status' => true,
            'data'   => $ordenes,
            'resumen' => $totales
        ]);
    }

    public function show($id)
    {
        $orden = OrdenCompra::with([
            'proveedor', 
            'usuario',
            'detalles.producto'
        ])->findOrFail($id);

        return response()->json([
            'status' => true,
            'data'   => $orden
        ]);
    }

    public function updateStatus(Request $request, $id)
    {
        $request->validate([
            'estado' => 'required|in:BORRADOR,ENVIADA,RECIBIDA,CANCELADA'
        ]);

        $orden = OrdenCompra::findOrFail($id);
        $orden->estado = $request->estado;
        $orden->save();

        return response()->json([
            'status' => true,
            'message' => 'Estado actualizado correctamente',
            'data' => $orden
        ]);
    }

    public function destroy($id)
    {
        $orden = OrdenCompra::findOrFail($id);
        
        // You might only allow deleting if it's BORRADOR
        if ($orden->estado !== 'BORRADOR' && $orden->estado !== 'CANCELADA') {
            return response()->json([
                'status' => false,
                'message' => 'Solo se pueden eliminar órdenes en estado BORRADOR o CANCELADA'
            ], 403);
        }

        $orden->delete();

        return response()->json([
            'status' => true,
            'message' => 'Orden de compra eliminada correctamente'
        ]);
    }

    public function generatePdf($id)
    {
        $orden = OrdenCompra::with(['proveedor', 'detalles'])->findOrFail($id);
        
        $pdf = Pdf::loadView('pdf.orden_compra', compact('orden'));
        
        return $pdf->stream("Orden_Compra_#{$orden->numero_orden}.pdf");
    }
}
