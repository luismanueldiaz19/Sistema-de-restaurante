<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Producto;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;
use Exception;

class ProductoController extends Controller
{
    /**
     * Display a listing of the resource.
     */
    public function index()
    {
        $productos = Producto::latest()->get();
        return response()->json($productos);
    }

    /**
     * Store a newly created resource in storage.
     */
    public function store(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'nombre'          => 'required|string|max:255',
            'codigo'          => 'nullable|string|unique:productos',
            'descripcion'     => 'nullable|string',
            'categoria'       => 'nullable|string',
            'unidad_medida'   => 'nullable|string|max:10',
            'precio_venta'    => 'required|numeric',
            'costo'           => 'nullable|numeric',
            'itbis_porcentaje'=> 'nullable|numeric',
            'maneja_inventario'=> 'nullable|boolean',
            'stock_actual'    => 'nullable|numeric',
            'stock_minimo'    => 'nullable|numeric',
            'cuenta_contable_ingresos'   => 'nullable|string',
            'cuenta_contable_inventario' => 'nullable|string',
            'cuenta_contable_costos'     => 'nullable|string',
            'activo'          => 'nullable|boolean',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'message' => 'Error en la validación',
                'errors' => $validator->errors()
            ], 400);
        }

        try {
            $producto = Producto::create($request->all());
            return response()->json([
                'message' => 'Producto creado correctamente',
                'data' => $producto
            ], 201);
        } catch (Exception $e) {
            return response()->json([
                'message' => 'Error al crear producto',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Display the specified resource.
     */
    public function show(string $id)
    {
        $producto = Producto::find($id);
        if (!$producto) {
            return response()->json(['message' => 'Producto no encontrado'], 404);
        }
        return response()->json($producto);
    }

    /**
     * Update the specified resource in storage.
     */
    public function update(Request $request, string $id) {
        $producto = Producto::find($id);
        if (!$producto) {
            return response()->json(['message' => 'Producto no encontrado'], 404);
        }

        $validator = Validator::make($request->all(), [
            'nombre'          => 'required|string|max:255',
            'codigo'          => 'nullable|string|unique:productos,codigo,' . $id,
            'descripcion'     => 'nullable|string',
            'categoria'       => 'nullable|string',
            'unidad_medida'   => 'nullable|string|max:10',
            'precio_venta'    => 'required|numeric',
            'costo'           => 'nullable|numeric',
            'itbis_porcentaje'=> 'nullable|numeric',
            'maneja_inventario'=> 'nullable|boolean',
            'stock_actual'    => 'nullable|numeric',
            'stock_minimo'    => 'nullable|numeric',
            'cuenta_contable_ingresos'   => 'nullable|string',
            'cuenta_contable_inventario' => 'nullable|string',
            'cuenta_contable_costos'     => 'nullable|string',
            'activo'          => 'nullable|boolean',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'message' => 'Error en la validación',
                'errors' => $validator->errors()
            ], 400);
        }

        try {
            $producto->update($request->all());
            return response()->json([
                'message' => 'Producto actualizado correctamente',
                'data' => $producto
            ], 200);
        } catch (Exception $e) {
            return response()->json([
                'message' => 'Error al actualizar producto',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Remove the specified resource from storage.
     */
    public function destroy(string $id)
    {
        $producto = Producto::find($id);
        if (!$producto) {
            return response()->json(['message' => 'Producto no encontrado'], 404);
        }

        try {
            $producto->delete();
            return response()->json(['message' => 'Producto eliminado correctamente'], 200);
        } catch (Exception $e) {
            return response()->json([
                'message' => 'Error al eliminar producto',
                'error' => $e->getMessage()
            ], 500);
        }
    }
}
