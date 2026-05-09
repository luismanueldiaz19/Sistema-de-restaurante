<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Factura;
use App\Models\FacturaDetalle;
use App\Models\Pago;
use Illuminate\Http\Request;
use App\Services\InventoryService;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Validator;
use Exception;


class FacturaController extends Controller {
 public function store(Request $request) {
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

        // 🔍 BUSCAR SESIÓN DE CAJA ACTIVA
        $sesionActiva = DB::table('caja_sesiones')
            ->where('user_id', auth()->id())
            ->where('estado', 'abierta')
            ->first();

        // ✅ CREAR FACTURA
        $factura = DB::table('facturas')->insertGetId([
            'cliente_id' => $request->cliente_id,
            'user_id' => auth()->id(),
            'caja_sesion_id' => $sesionActiva ? $sesionActiva->id : null, // 👈 Vincular a sesión
            'ncf' => $ncf,
            'tipo_factura' => $tipoFactura,
            'dias_credito' => $request->dias_credito ?? 0,
            'nota' => $request->nota,
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
                'producto_id' => $item['producto_id'] ?? null,
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

            // 🔥 DESCONTAR INVENTARIO (Si hay producto_id)
            if (!empty($item['producto_id'])) {
                app(InventoryService::class)->procesarVenta($item['producto_id'], $item['cantidad'], $ncf);
            }
        }

        // 💳 REGISTRAR PAGO (Si viene en la petición)
        if ($request->has('pago')) {
            $pagoData = $request->pago;
            DB::table('pagos')->insert([
                'factura_id' => $factura,
                'user_id' => auth()->id(),
                'caja_sesion_id' => $sesionActiva ? $sesionActiva->id : null,
                'monto_pagado' => $pagoData['monto_pagado'],
                'monto_recibido' => $pagoData['monto_recibido'],
                'devuelta' => $pagoData['devuelta'] ?? 0,
                'metodo_pago' => $pagoData['metodo_pago'] ?? 'efectivo',
                'referencia_pago' => $pagoData['referencia_pago'] ?? null,
                'fecha_pago' => now(),
                'created_at' => now(),
                'updated_at' => now(),
            ]);

            // Si el pago cubre el total, marcar factura como pagada
            if ($pagoData['monto_pagado'] >= $total - 0.01) { // Pequeño margen por redondeo
                DB::table('facturas')->where('id', $factura)->update(['estado' => 'pagada']);
            }
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

    public function index(Request $request)
    {
        $query = Factura::with('cliente', 'detalles', 'user')
            ->orderBy('fecha_emision', 'desc');

        // Si no es admin, solo puede ver sus propias facturas
        if (!$request->user()->hasRole('admin')) {
            $query->where('user_id', $request->user()->id);
        }

        if ($request->filled('fecha_desde')) {
            $query->where('fecha_emision', '>=', $request->fecha_desde);
        }

        if ($request->filled('fecha_hasta')) {
            $query->where('fecha_emision', '<=', $request->fecha_hasta . ' 23:59:59');
        }

        if ($request->filled('cliente_id')) {
            $query->where('cliente_id', $request->cliente_id);
        }

        if ($request->filled('estado')) {
            $query->where('estado', $request->estado);
        }

        if ($request->filled('caja_sesion_id')) {
            $query->where('caja_sesion_id', $request->caja_sesion_id);
        }

        // --- CÁLCULO DE RESUMEN FILTRADO ---
        $resumenQuery = clone $query;
        $totales = $resumenQuery->reorder()->selectRaw('
            COUNT(*) as cantidad_facturas, 
            SUM(total) as total_venta, 
            SUM(itbis) as total_itbis, 
            SUM(descuento_total) as total_descuento
        ')->first();

        // Obtener desglose por método de pago para las facturas filtradas
        $facturaIds = (clone $query)->pluck('id');
        $porMetodo = DB::table('pagos')
            ->whereIn('factura_id', $facturaIds)
            ->selectRaw('metodo_pago, sum(monto_pagado) as total')
            ->groupBy('metodo_pago')
            ->get();

        $facturas = $query->paginate($request->per_page ?? 15);

        return response()->json([
            'status' => true,
            'data'   => $facturas,
            'resumen' => [
                'totales' => $totales,
                'por_metodo' => $porMetodo
            ]
        ]);
    }

    /**
     * Reportes agrupados de ventas
     */
    public function reportes(Request $request)
    {
        try {
            $fechaDesde = $request->fecha_desde;
            $fechaHasta = $request->fecha_hasta ? $request->fecha_hasta . ' 23:59:59' : null;

            // 1. Agrupado por Método de Pago
            $porMetodo = DB::table('pagos')
                ->selectRaw('metodo_pago, count(*) as cantidad, sum(monto_pagado) as total')
                ->when($fechaDesde, fn($q) => $q->where('fecha_pago', '>=', $fechaDesde))
                ->when($fechaHasta, fn($q) => $q->where('fecha_pago', '<=', $fechaHasta))
                ->groupBy('metodo_pago')
                ->get();

            // 2. Agrupado por Cajero
            $porCajero = DB::table('facturas')
                ->join('users', 'users.id', '=', 'facturas.user_id')
                ->selectRaw('users.name as cajero, count(*) as cantidad, sum(facturas.total) as total')
                ->when($fechaDesde, fn($q) => $q->where('fecha_emision', '>=', $fechaDesde))
                ->when($fechaHasta, fn($q) => $q->where('fecha_emision', '<=', $fechaHasta))
                ->groupBy('users.name')
                ->get();

            // 3. Agrupado por Tipo de Factura
            $porTipo = DB::table('facturas')
                ->selectRaw('tipo_factura, count(*) as cantidad, sum(facturas.total) as total')
                ->when($fechaDesde, fn($q) => $q->where('fecha_emision', '>=', $fechaDesde))
                ->when($fechaHasta, fn($q) => $q->where('fecha_emision', '<=', $fechaHasta))
                ->groupBy('tipo_factura')
                ->get();

            return response()->json([
                'status' => true,
                'data'   => [
                    'por_metodo' => $porMetodo,
                    'por_cajero' => $porCajero,
                    'por_tipo'   => $porTipo,
                ]
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'status' => false,
                'message' => 'Error en reporte: ' . $e->getMessage()
            ], 500);
        }
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
