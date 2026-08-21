<?php

namespace App\Http\Controllers\Api\Inventario;

use App\Http\Controllers\Controller;
use App\Models\Producto;
use App\Models\Receta;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class RecetaController extends Controller
{
    /**
     * List all products that have recipes or can have recipes (COMBO or PRODUCTO).
     */
    public function index()
    {
        $productos = Producto::with(['recetas.ingrediente'])
            ->whereIn('tipo_producto', ['COMBO', 'PRODUCTO'])
            ->get();

        return response()->json([
            'message' => 'Lista de productos con recetas',
            'data' => $productos
        ], 200);
    }

    /**
     * Get the recipe for a specific product.
     */
    public function show($id)
    {
        $producto = Producto::with(['recetas.ingrediente'])->findOrFail($id);

        return response()->json([
            'message' => 'Receta del producto',
            'data' => $producto->recetas
        ], 200);
    }

    /**
     * Update the recipe for a specific product.
     */
    public function update(Request $request, $id)
    {
        $producto = Producto::findOrFail($id);

        if (!in_array($producto->tipo_producto, ['COMBO', 'PRODUCTO'])) {
            return response()->json([
                'message' => 'Este producto no admite recetas.'
            ], 400);
        }

        $request->validate([
            'ingredientes' => 'array',
            'ingredientes.*.ingrediente_producto_id' => 'required|exists:productos,id',
            'ingredientes.*.cantidad' => 'required|numeric|min:0.01',
        ]);

        try {
            DB::beginTransaction();

            // Clear old recipe
            Receta::where('producto_id', $producto->id)->delete();

            // Add new recipe
            $ingredientes = $request->input('ingredientes', []);
            $recetas = [];

            foreach ($ingredientes as $item) {
                // Check that the ingredient is actually a MATERIA_PRIMA or PRODUCTO
                $ingredienteModel = Producto::find($item['ingrediente_producto_id']);
                
                $recetas[] = Receta::create([
                    'producto_id' => $producto->id,
                    'ingrediente_producto_id' => $item['ingrediente_producto_id'],
                    'cantidad' => $item['cantidad']
                ]);
            }

            DB::commit();

            return response()->json([
                'message' => 'Receta actualizada correctamente.',
                'data' => $producto->load('recetas.ingrediente')
            ], 200);
        } catch (\Exception $e) {
            DB::rollBack();
            return response()->json([
                'message' => 'Error al actualizar receta',
                'error' => $e->getMessage()
            ], 500);
        }
    }
}

