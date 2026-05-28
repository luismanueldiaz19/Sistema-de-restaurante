<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Producto;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;
use Exception;

class ProductoController extends Controller
{
    public function index()
    {
        $productos = Producto::with(['categoria', 'marca', 'unidadMedida', 'impuesto'])->latest()->get();
        return response()->json($productos);
    }

    public function store(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'nombre'          => 'required|string|max:255',
            'codigo'          => 'nullable|string|unique:productos',
            'descripcion'     => 'nullable|string',
            'categoria_id'    => 'nullable|integer|exists:categorias,id',
            'marca_id'        => 'nullable|integer|exists:marcas,id',
            'unidad_medida_id'=> 'nullable|integer|exists:unidades_medida,id',
            'impuesto_id'     => 'nullable|integer|exists:impuestos,id',
            'tipo_producto'   => 'required|in:PRODUCTO,SERVICIO,COMBO',
            'tipo_contable'   => 'required|in:INVENTARIO,GASTO,SERVICIO,ACTIVO_FIJO',
            'precio_venta'    => 'required|numeric',
            'ultimo_costo'    => 'nullable|numeric',
            'costo_promedio'  => 'nullable|numeric',
            'maneja_inventario'=> 'nullable|boolean',
            'stock_minimo'    => 'nullable|numeric',
            'cuenta_ingreso_id'=> 'nullable|integer',
            'cuenta_inventario_id'=> 'nullable|integer',
            'cuenta_costo_id' => 'nullable|integer',
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
            $producto->load(['categoria', 'marca', 'unidadMedida', 'impuesto']);
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

    public function show(string $id)
    {
        $producto = Producto::with(['categoria', 'marca', 'unidadMedida', 'impuesto'])->find($id);
        if (!$producto) {
            return response()->json(['message' => 'Producto no encontrado'], 404);
        }
        return response()->json($producto);
    }

    public function update(Request $request, string $id) {
        $producto = Producto::find($id);
        if (!$producto) {
            return response()->json(['message' => 'Producto no encontrado'], 404);
        }

        $validator = Validator::make($request->all(), [
            'nombre'          => 'required|string|max:255',
            'codigo'          => 'nullable|string|unique:productos,codigo,' . $id,
            'descripcion'     => 'nullable|string',
            'categoria_id'    => 'nullable|integer|exists:categorias,id',
            'marca_id'        => 'nullable|integer|exists:marcas,id',
            'unidad_medida_id'=> 'nullable|integer|exists:unidades_medida,id',
            'impuesto_id'     => 'nullable|integer|exists:impuestos,id',
            'tipo_producto'   => 'required|in:PRODUCTO,SERVICIO,COMBO',
            'tipo_contable'   => 'required|in:INVENTARIO,GASTO,SERVICIO,ACTIVO_FIJO',
            'precio_venta'    => 'required|numeric',
            'ultimo_costo'    => 'nullable|numeric',
            'costo_promedio'  => 'nullable|numeric',
            'maneja_inventario'=> 'nullable|boolean',
            'stock_minimo'    => 'nullable|numeric',
            'cuenta_ingreso_id'=> 'nullable|integer',
            'cuenta_inventario_id'=> 'nullable|integer',
            'cuenta_costo_id' => 'nullable|integer',
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
            $producto->load(['categoria', 'marca', 'unidadMedida', 'impuesto']);
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
