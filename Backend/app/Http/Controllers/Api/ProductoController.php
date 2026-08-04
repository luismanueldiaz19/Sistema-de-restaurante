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
            'impuesto_venta_id'  => 'nullable|integer|exists:impuestos,id',
            'impuesto_compra_id' => 'nullable|integer|exists:impuestos,id',
            'tipo_producto'   => 'required|in:PRODUCTO,SERVICIO,COMBO',
            'tipo_contable'   => 'required|in:INVENTARIO,GASTO,SERVICIO,ACTIVO_FIJO',
            'precio_venta'    => 'required|numeric',
            'precio_incluye_impuesto'=> 'nullable|boolean',
            'costo'           => 'nullable|numeric',
            'maneja_inventario'=> 'nullable|boolean',
            'maneja_vencimiento'=> 'nullable|boolean',
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
            'impuesto_venta_id'  => 'nullable|integer|exists:impuestos,id',
            'impuesto_compra_id' => 'nullable|integer|exists:impuestos,id',
            'tipo_producto'   => 'required|in:PRODUCTO,SERVICIO,COMBO',
            'tipo_contable'   => 'required|in:INVENTARIO,GASTO,SERVICIO,ACTIVO_FIJO',
            'precio_venta'    => 'required|numeric',
            'precio_incluye_impuesto'=> 'nullable|boolean',
            'costo'           => 'nullable|numeric',
            'maneja_inventario'=> 'nullable|boolean',
            'maneja_vencimiento'=> 'nullable|boolean',
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

    public function import(Request $request)
    {
        $request->validate([
            'documento' => 'required|file|max:20480',
        ]);

        $file = $request->file('documento');
        $path = $file->getRealPath();

        try {
            $data = (new \Rap2hpoutre\FastExcel\FastExcel)->import($path);
        } catch (\Exception $e) {
            return response()->json(['message' => 'Error leyendo el archivo: ' . $e->getMessage()], 400);
        }

        if ($data->isEmpty()) {
            return response()->json(['message' => 'El archivo está vacío o no tiene el formato correcto'], 400);
        }

        $exitosos = 0;
        $errores = [];

        foreach ($data as $index => $row) {
            // Normalizar llaves a minúsculas para evitar problemas de mayúsculas/minúsculas
            $normalizedRow = [];
            foreach ($row as $key => $value) {
                $normalizedRow[trim(strtolower($key))] = $value;
            }

            // Mapeo flexible de columnas
            $nombre = $normalizedRow['nombre'] ?? null;
            $codigo = $normalizedRow['codigo'] ?? null;
            $descripcion = $normalizedRow['descripcion'] ?? $normalizedRow['destalle'] ?? $normalizedRow['detalle'] ?? null;
            $tipo_producto = $normalizedRow['tipo_producto'] ?? $normalizedRow['tipo'] ?? null;
            $tipo_contable = $normalizedRow['tipo_contable'] ?? $normalizedRow['contable'] ?? null;
            $precio_venta = $normalizedRow['precio_venta'] ?? $normalizedRow['precio'] ?? null;
            $costo = $normalizedRow['costo'] ?? 0;
            $impuesto_id = $normalizedRow['impuesto_id'] ?? $normalizedRow['itbis'] ?? null;
            $stock_actual = $normalizedRow['stock_actual'] ?? $normalizedRow['stock'] ?? 0;
            $stock_minimo = $normalizedRow['stock_minimo'] ?? 0;
            $maneja_inventario = $normalizedRow['maneja_inventario'] ?? $normalizedRow['inventario'] ?? true;

            // Validar requeridos
            if (empty($nombre) || empty($tipo_producto) || empty($tipo_contable) || !isset($precio_venta) || $precio_venta === '') {
                $errores[] = "Fila " . ($index + 2) . ": Faltan campos requeridos (nombre, tipo, contable, precio).";
                continue;
            }

            // Convertir booleanos textuales si aplican
            if (is_string($maneja_inventario)) {
                $maneja_inventario = filter_var($maneja_inventario, FILTER_VALIDATE_BOOLEAN);
            }

            try {
                if ($codigo) {
                    $producto = Producto::where('codigo', $codigo)->first();
                    if ($producto) {
                        $producto->update([
                            'nombre' => $nombre,
                            'descripcion' => $descripcion ?? $producto->descripcion,
                            'tipo_producto' => $tipo_producto,
                            'tipo_contable' => $tipo_contable,
                            'precio_venta' => $precio_venta,
                            'costo' => $costo !== 0 ? $costo : $producto->costo,
                            'stock_actual' => $stock_actual !== 0 ? $stock_actual : $producto->stock_actual,
                            'stock_minimo' => $stock_minimo !== 0 ? $stock_minimo : $producto->stock_minimo,
                            'impuesto_id'  => !empty($impuesto_id) ? $impuesto_id : $producto->impuesto_id,
                            'maneja_inventario' => $maneja_inventario,
                        ]);
                        $exitosos++;
                        continue;
                    }
                }

                Producto::create([
                    'nombre' => $nombre,
                    'codigo' => $codigo,
                    'descripcion' => $descripcion,
                    'tipo_producto' => $tipo_producto,
                    'tipo_contable' => $tipo_contable,
                    'precio_venta' => $precio_venta,
                    'costo' => $costo,
                    'stock_actual' => $stock_actual,
                    'stock_minimo' => $stock_minimo,
                    'impuesto_id'  => !empty($impuesto_id) ? $impuesto_id : null,
                    'maneja_inventario' => $maneja_inventario,
                    'activo' => true,
                ]);
                $exitosos++;
            } catch (Exception $e) {
                $errores[] = "Fila " . ($index + 2) . ": Error - " . $e->getMessage();
            }
        }

        return response()->json([
            'message' => "Importación completada. $exitosos procesados con éxito.",
            'errores' => $errores
        ], 200);
    }
}
