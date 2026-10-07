<?php

declare(strict_types=1);

namespace App\Modules\Producto\Http\Controllers;

use App\Http\Controllers\Controller;
use App\Modules\Producto\DTOs\CreateProductoDTO;
use App\Modules\Producto\DTOs\UpdateProductoDTO;
use App\Modules\Producto\Http\Requests\StoreProductoRequest;
use App\Modules\Producto\Http\Requests\UpdateProductoRequest;
use App\Modules\Producto\Http\Resources\ProductoResource;
use App\Modules\Producto\Services\ProductoService;
use App\Modules\Shared\Traits\ApiResponseTrait;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ProductoController extends Controller
{
    use ApiResponseTrait;

    public function __construct(
        private readonly ProductoService $productoService
    ) {}

    public function index(Request $request): JsonResponse
    {
        $perPage = (int) $request->input('per_page', 15);
        $filters = [
            'search' => $request->input('search'),
            'categoria_id' => $request->input('categoria_id'),
            'marca_id' => $request->input('marca_id'),
            'tipo_producto' => $request->input('tipo_producto'),
        ];

        $productos = $this->productoService->getAll($perPage, $filters);

        return $this->successResponse(
            data: ProductoResource::collection($productos)->response()->getData(true),
            message: 'Productos obtenidos exitosamente'
        );
    }

    public function store(StoreProductoRequest $request): JsonResponse
    {
        $dto = CreateProductoDTO::fromRequest($request);
        $producto = $this->productoService->create($dto);

        return $this->successResponse(
            data: new ProductoResource($producto),
            message: 'Producto creado exitosamente',
            code: 201
        );
    }

    public function show(int $id): JsonResponse
    {
        $producto = $this->productoService->getById($id);

        return $this->successResponse(
            data: new ProductoResource($producto),
            message: 'Producto obtenido exitosamente'
        );
    }

    public function update(UpdateProductoRequest $request, int $id): JsonResponse
    {
        $dto = UpdateProductoDTO::fromRequest($request);
        $producto = $this->productoService->update($id, $dto);

        return $this->successResponse(
            data: new ProductoResource($producto),
            message: 'Producto actualizado exitosamente'
        );
    }

    public function destroy(int $id): JsonResponse
    {
        $this->productoService->delete($id);

        return $this->successResponse(
            message: 'Producto eliminado exitosamente'
        );
    }

    public function import(Request $request): JsonResponse
    {
        $request->validate([
            'documento' => 'required|file|max:20480',
        ]);

        $file = $request->file('documento');
        $path = $file->getRealPath();

        try {
            $data = (new \Rap2hpoutre\FastExcel\FastExcel)->import($path);
        } catch (\Exception $e) {
            return $this->errorResponse('Error leyendo el archivo: ' . $e->getMessage(), 400);
        }

        if ($data->isEmpty()) {
            return $this->errorResponse('El archivo está vacío o no tiene el formato correcto', 400);
        }

        $exitosos = 0;
        $errores = [];

        foreach ($data as $index => $row) {
            $normalizedRow = [];
            foreach ($row as $key => $value) {
                $normalizedRow[trim(strtolower((string)$key))] = $value;
            }

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

            if (empty($nombre) || empty($tipo_producto) || empty($tipo_contable) || !isset($precio_venta) || $precio_venta === '') {
                $errores[] = "Fila " . ($index + 2) . ": Faltan campos requeridos (nombre, tipo, contable, precio).";
                continue;
            }

            if (is_string($maneja_inventario)) {
                $maneja_inventario = filter_var($maneja_inventario, FILTER_VALIDATE_BOOLEAN);
            }

            try {
                if ($codigo) {
                    $producto = \App\Models\Producto::where('codigo', $codigo)->first();
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

                \App\Models\Producto::create([
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
            } catch (\Exception $e) {
                $errores[] = "Fila " . ($index + 2) . ": Error - " . $e->getMessage();
            }
        }

        return response()->json([
            'success' => true,
            'message' => "Importación completada. $exitosos procesados con éxito.",
            'errores' => $errores
        ], 200);
    }
}
