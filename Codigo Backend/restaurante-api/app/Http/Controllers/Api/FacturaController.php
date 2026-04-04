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
            'ncf_secuencia_id' => 'required|exists:ncf_secuencias,id',
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

        // 🔥 GENERAR NCF
        $secuencia = $this->generarNCF($request->ncf_secuencia_id);
        $ncf = $secuencia['ncf'];
        $tipoFactura = $secuencia['nombre'];

        $detalles = $request->detalles;

        $subtotal = 0;
        $itbisTotal = 0;
        $descuentoTotal = 0;

        $detallesCalculados = [];

        // 🧮 CALCULAR TODO PRIMERO
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

        // ✅ CREAR FACTURA
        $factura = DB::table('facturas')->insertGetId([
            'cliente_id' => $request->cliente_id,
            'user_id' => auth()->id(),
            'ncf' => $ncf,
            'tipo_factura' => $tipoFactura,
            'fecha_emision' => $request->fecha_emision,
            'fecha_vencimiento' => $request->fecha_vencimiento,
            'subtotal' => round($subtotal, 2),
            'descuento_total' => round($descuentoTotal, 2),
            'itbis' => round($itbisTotal, 2),
            'total' => round($total, 2),
            'estado' => 'pendiente',
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        // ✅ INSERTAR DETALLES
        foreach ($detallesCalculados as $detalle) {

            $item = $detalle['item'];
            $calc = $detalle['calc'];

            DB::table('factura_detalle')->insert([
                'factura_id' => $factura,
                'descripcion' => $item['descripcion'],
                'unidad_medida' => $item['unidad_medida'] ?? null,
                'cantidad' => $item['cantidad'],
                'precio' => $item['precio'],
                'descuento' => round($calc['descuento'], 2),
                'descuento_porcentaje' => $item['descuento_porcentaje'] ?? 0,
                'itbis' => round($calc['itbis'], 2),
                'total' => round($calc['total'], 2),
                'created_at' => now(),
                'updated_at' => now(),
            ]);
        }

        DB::commit();

        return response()->json([
            'message' => 'Factura creada correctamente',
            'status' => 201,
            'factura_id' => $factura,
            'ncf' => $ncf,
            'tipo_factura' => $tipoFactura
        ], 201);

    } catch (\Exception $e) {

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


private function generarNCF($id) {
    $sec = DB::table('ncf_secuencias')
        ->where('id', $id)
        ->lockForUpdate()
        ->first();

    if (!$sec || !$sec->activo) {
        throw new \Exception("Secuencia no válida");
    }

    $nuevo = $sec->actual + 1;

    if ($nuevo > $sec->rango_fin) {
        throw new \Exception("Secuencia agotada");
    }

    DB::table('ncf_secuencias')
        ->where('id', $id)
        ->update(['actual' => $nuevo]);

         $ncf = $sec->prefijo . $sec->tipo . str_pad($nuevo, 10, '0', STR_PAD_LEFT);

     return [
        'ncf' => $ncf,
        'tipo' => $sec->tipo,
        'nombre' => $sec->nombre
    ];
}


private function calcularLinea($item)
{
    $cantidad = $item['cantidad'];
    $precio = $item['precio']; // ya incluye ITBIS

    $linea = $cantidad * $precio;

    // 🔥 separar base
    $base = $linea / 1.18;

    // 🎯 DESCUENTO
    $descuento = $item['descuento'] ?? 0;

    if (!empty($item['descuento_porcentaje'])) {
        $descuento = $base * ($item['descuento_porcentaje'] / 100);
    }

    // ❌ VALIDACIONES IMPORTANTES
    if ($descuento > $base) {
        throw new \Exception("El descuento no puede ser mayor que el precio base");
    }

    if ($descuento < 0) {
        throw new \Exception("El descuento no puede ser negativo");
    }

    // 🔥 cálculo final
    $baseConDescuento = $base - $descuento;
    $itbis = $baseConDescuento * 0.18;
    $total = $baseConDescuento + $itbis;

    return [
        'base' => $base,
        'descuento' => $descuento,
        'baseConDescuento' => $baseConDescuento,
        'itbis' => $itbis,
        'total' => $total
    ];
}

}
