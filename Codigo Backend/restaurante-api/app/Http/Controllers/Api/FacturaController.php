<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Factura;
use App\Models\FacturaDetalle;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class FacturaController extends Controller
{
    public function store(Request $request)
    {
        DB::beginTransaction();

        try {

            $subtotal   = 0;
            $itbisTotal = 0;

            // calcular totales
            foreach ($request->items as $item) {

                $sub   = $item['cantidad'] * $item['precio'];
                $itbis = $sub              * 0.18;

                $subtotal   += $sub;
                $itbisTotal += $itbis;
            }

            $total = $subtotal + $itbisTotal;

            // crear factura
            $factura = Factura::create([
                'cliente_id' => $request->cliente_id,
                'fecha'      => now(),
                'subtotal'   => $subtotal,
                'itbis'      => $itbisTotal,
                'total'      => $total,
                'estado'     => 'pendiente'
            ]);

            // guardar detalle
            foreach ($request->items as $item) {

                $sub   = $item['cantidad'] * $item['precio'];
                $itbis = $sub              * 0.18;

                FacturaDetalle::create([
                    'factura_id'  => $factura->id,
                    'descripcion' => $item['descripcion'],
                    'cantidad'    => $item['cantidad'],
                    'precio'      => $item['precio'],
                    'itbis'       => $itbis,
                    'subtotal'    => $sub
                ]);
            }

            DB::commit();

            return response()->json([
                'status'  => true,
                'message' => 'Factura creada correctamente',
                'data'    => $factura
            ]);

        } catch (\Exception $e) {
            DB::rollBack();

            return response()->json([
                'status'  => false,
                'message' => $e->getMessage()
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

    public function show($id)
    {
        $factura = Factura::with('cliente', 'detalles')->findOrFail($id);

        return response()->json([
            'status' => true,
            'data'   => $factura
        ]);
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
