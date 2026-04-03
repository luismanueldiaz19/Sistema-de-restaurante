<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Factura;
use App\Models\FacturaDetalle;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Validator;
use Exception;


class FacturaController extends Controller
{
    public function store(Request $request)
{
    DB::beginTransaction();

    try {

        // ✅ VALIDACIÓN
        $validator = Validator::make($request->all(), [
            'cliente_id' => 'required|exists:clientes,id',
            'ncf' => 'required|unique:facturas,ncf',
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

        // 🧮 CALCULAR DETALLES
        foreach ($detalles as $item) {

            $cantidad = $item['cantidad'];
            $precio = $item['precio'];

            $linea = $cantidad * $precio;

            // 🎯 DESCUENTO
            $descuento = $item['descuento'] ?? 0;

            if (!empty($item['descuento_porcentaje'])) {
                $descuento = $linea * ($item['descuento_porcentaje'] / 100);
            }

            $lineaConDescuento = $linea - $descuento;

            // 💰 ITBIS (18%)
            $itbis = $lineaConDescuento * 0.18;

            $subtotal += $linea;
            $descuentoTotal += $descuento;
            $itbisTotal += $itbis;
        }

        $total = ($subtotal - $descuentoTotal) + $itbisTotal;

        // ✅ CREAR FACTURA
        $factura = DB::table('facturas')->insertGetId([
            'cliente_id' => $request->cliente_id,
            'user_id' => auth()->id(),// 👈 vendedor
            'ncf' => $request->ncf,
            'tipo_factura' => $request->tipo_factura ?? 'consumo_final',
            'fecha_emision' => $request->fecha_emision,
            'fecha_vencimiento' => $request->fecha_vencimiento,
            'subtotal' => $subtotal,
            'descuento_total' => $descuentoTotal,
            'itbis' => $itbisTotal,
            'total' => $total,
            'estado' => 'pendiente',
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        // ✅ GUARDAR DETALLES
        foreach ($detalles as $item) {

            $cantidad = $item['cantidad'];
            $precio = $item['precio'];

            $linea = $cantidad * $precio;

            $descuento = $item['descuento'] ?? 0;

            if (!empty($item['descuento_porcentaje'])) {
                $descuento = $linea * ($item['descuento_porcentaje'] / 100);
            }

            $lineaConDescuento = $linea - $descuento;
            $itbis = $lineaConDescuento * 0.18;
            $totalLinea = $lineaConDescuento + $itbis;

            DB::table('factura_detalle')->insert([
                'factura_id' => $factura,
                'descripcion' => $item['descripcion'],
                'unidad_medida' => $item['unidad_medida'] ?? null,
                'cantidad' => $cantidad,
                'precio' => $precio,
                'descuento' => $descuento,
                'descuento_porcentaje' => $item['descuento_porcentaje'] ?? 0,
                'itbis' => $itbis,
                'total' => $totalLinea,
                'created_at' => now(),
                'updated_at' => now(),
            ]);
        }

        DB::commit();

        return response()->json([
            'message' => 'Factura creada correctamente',
            'status' => 201,
            'factura_id' => $factura
        ], 201);

    } catch (Exception $e) {

        DB::rollBack();

        return response()->json([
            'message' => 'Error al crear factura',
            'error' => $e->getMessage(),
            'status' => 500
        ], 500);
    }
}

    public function index()
    {
        $facturas = Factura::with('cliente', 'detalles')
            ->latest()
            ->get();

        return response()->json([
            'status' => true,
            'data'   => $facturas
        ]);
    }

   public function show($id) {
    try {
        $factura = Factura::with([
            'cliente',
            'detalles',
            'user'
        ])->find($id);

        if (!$factura) {
            return response()->json([
                'message' => 'Factura no encontrada',
                'status' => 404
            ], 404);
        }

        return response()->json([
            'message' => 'Factura encontrada',
            'status' => 200,
            'data' => $factura
        ], 200);

    } catch (\Exception $e) {
        return response()->json([
            'message' => 'Error al obtener factura',
            'error' => $e->getMessage(),
            'status' => 500
        ], 500);
    }
}

    public function pagar($id)
    {
        $factura = Factura::findOrFail($id);

        $factura->update([
            'estado' => 'pagada'
        ]);

        return response()->json([
            'status'  => true,
            'message' => 'Factura pagada'
        ]);
    }

}
