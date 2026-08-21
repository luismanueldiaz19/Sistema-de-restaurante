<?php

namespace App\Http\Controllers\Api\Inventario;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Producto;
use App\Models\MovimientoInventario;
use Illuminate\Support\Facades\DB;

class AjusteInventarioController extends Controller
{
    public function index()
    {
        $movimientos = MovimientoInventario::with('producto')
            ->orderBy('created_at', 'desc')
            ->get();
        return response()->json(['data' => $movimientos]);
    }

    public function store(Request $request)
    {
        $request->validate([
            'producto_id' => 'required|exists:productos,id',
            'tipo' => 'required|in:ENTRADA,SALIDA',
            'cantidad' => 'required|numeric|min:0.01',
            'motivo' => 'required|string|max:255'
        ]);

        try {
            DB::beginTransaction();

            $producto = Producto::findOrFail($request->producto_id);

            $cantidad = (double) $request->cantidad;

            if ($request->tipo === 'ENTRADA') {
                $producto->stock_actual += $cantidad;
            } else {
                $producto->stock_actual -= $cantidad;
            }

            $producto->save();

            $movimiento = MovimientoInventario::create([
                'producto_id' => $producto->id,
                'tipo' => $request->tipo,
                'cantidad' => $cantidad,
                'referencia' => $request->motivo,
                'fecha' => now()
            ]);

            DB::commit();

            return response()->json([
                'message' => 'Ajuste de inventario guardado correctamente',
                'data' => $movimiento
            ], 201);

        } catch (\Exception $e) {
            DB::rollBack();
            return response()->json(['error' => 'Error al guardar el ajuste: ' . $e->getMessage()], 500);
        }
    }
}

