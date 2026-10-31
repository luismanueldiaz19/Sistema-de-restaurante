<?php

declare(strict_types=1);

namespace App\Modules\Producto\Http\Controllers;

use App\Http\Controllers\Controller;
use App\Modules\Producto\DTOs\CreateProductoDTO;
use App\Modules\Producto\DTOs\UpdateProductoDTO;
use App\Modules\Producto\Exceptions\ProductoException;
use App\Modules\Producto\Http\Requests\StoreProductoRequest;
use App\Modules\Producto\Http\Requests\UpdateProductoRequest;
use App\Modules\Producto\Http\Resources\ProductoResource;
use App\Modules\Producto\Services\ProductoService;
use App\Modules\Shared\Traits\ApiResponseTrait;
use Exception;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Rap2hpoutre\FastExcel\FastExcel;
use Symfony\Component\HttpFoundation\BinaryFileResponse;

class ProductoController extends Controller
{
    use ApiResponseTrait;

    public function __construct(
        private readonly ProductoService $productoService
    ) {}

    public function index(Request $request): JsonResponse
    {
        $perPage = (int) $request->input('per_page', 300);
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

    public function paraCompras(Request $request): JsonResponse
    {
        $perPage = (int) $request->input('per_page', 300);
        $filters = [
            'search' => $request->input('search'),
            'categoria_id' => $request->input('categoria_id'),
            'marca_id' => $request->input('marca_id'),
            'exclude_tipo_producto' => ['PLATO', 'COMBO', 'SERVICIO'],
        ];

        $productos = $this->productoService->getAll($perPage, $filters);

        return $this->successResponse(
            data: ProductoResource::collection($productos)->response()->getData(true),
            message: 'Productos para compras obtenidos exitosamente'
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

    /**
     * Descarga la plantilla base Excel (.xlsx) para productos inventariables.
     */
    public function downloadTemplate(): BinaryFileResponse|JsonResponse
    {
        try {
            $filas = collect($this->productoService->obtenerFilasPlantillaBase());
            $tempPath = storage_path('app/plantilla_productos_inventariables_' . uniqid() . '.xlsx');

            (new FastExcel($filas))->export($tempPath);

            return response()->download(
                $tempPath,
                'plantilla_productos_inventariables.xlsx',
                [
                    'Content-Type' => 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
                ]
            )->deleteFileAfterSend(true);
        } catch (Exception $e) {
            return $this->errorResponse('Error generando la plantilla: ' . $e->getMessage(), 500);
        }
    }

    /**
     * Previsualiza y valida el archivo Excel/CSV antes de guardarlo en la base de datos.
     */
    public function previewImport(Request $request): JsonResponse
    {
        $request->validate([
            'documento' => 'required|file|max:20480',
        ]);

        $file = $request->file('documento');
        $path = $file->getRealPath();

        try {
            $resultado = $this->productoService->previsualizarImportacion((string) $path);

            return $this->successResponse(
                data: $resultado,
                message: 'Archivo validado exitosamente para previsualización.'
            );
        } catch (ProductoException $e) {
            return $this->errorResponse($e->getMessage(), 400);
        } catch (Exception $e) {
            return $this->errorResponse('Error procesando el archivo: ' . $e->getMessage(), 400);
        }
    }

    /**
     * Confirma y guarda masivamente los productos revisados por el usuario en la previsualización.
     */
    public function confirmImport(Request $request): JsonResponse
    {
        $request->validate([
            'productos' => 'required|array|min:1',
            'productos.*.nombre' => 'required|string',
        ]);

        try {
            $resultado = $this->productoService->confirmarImportacionMasiva($request->input('productos'));

            return $this->successResponse(
                data: $resultado,
                message: "Importación completada exitosamente: {$resultado['creados']} productos registrados."
            );
        } catch (Exception $e) {
            return $this->errorResponse('Error en la importación masiva: ' . $e->getMessage(), 400);
        }
    }

    /**
     * Endpoint directo de importación (compatibilidad).
     */
    public function import(Request $request): JsonResponse
    {
        $request->validate([
            'documento' => 'required|file|max:20480',
        ]);

        $file = $request->file('documento');
        $path = $file->getRealPath();

        try {
            $preview = $this->productoService->previsualizarImportacion((string) $path);
            $filasListas = array_values(array_filter(
                $preview['filas'],
                fn ($f) => ($f['estado'] ?? '') === 'LISTO'
            ));

            if (empty($filasListas)) {
                return $this->errorResponse('No se encontraron productos nuevos válidos para importar (verifique duplicados o errores).', 400, $preview);
            }

            $resultado = $this->productoService->confirmarImportacionMasiva($filasListas);

            return response()->json([
                'success' => true,
                'message' => "Importación completada: {$resultado['creados']} creados, {$preview['resumen']['duplicados']} duplicados omitidos.",
                'data'    => $resultado,
                'errores' => $resultado['errores'],
            ], 200);
        } catch (Exception $e) {
            return $this->errorResponse('Error al importar: ' . $e->getMessage(), 400);
        }
    }
}
