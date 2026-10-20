<?php

declare(strict_types=1);

namespace App\Modules\Inventario\Http\Controllers;

use App\Http\Controllers\Controller;
use App\Modules\Inventario\DTOs\GuardarRecetaDTO;
use App\Modules\Inventario\Exceptions\InventarioException;
use App\Modules\Inventario\Http\Requests\GuardarRecetaRequest;
use App\Modules\Inventario\Services\RecetaService;
use App\Modules\Shared\Traits\ApiResponseTrait;
use Illuminate\Http\JsonResponse;

class RecetaController extends Controller
{
    use ApiResponseTrait;

    public function __construct(
        private readonly RecetaService $recetaService
    ) {}

    /**
     * Listar todos los productos con sus recetas configuradas
     */
    public function index(): JsonResponse
    {
        try {
            $productos = $this->recetaService->getProductosConRecetas();

            return $this->successResponse(
                data: $productos,
                message: 'Lista de productos con recetas'
            );
        } catch (\Exception $e) {
            return $this->errorResponse(
                message: 'Error al obtener recetas: ' . $e->getMessage(),
                code: 500
            );
        }
    }

    /**
     * Obtener la receta de un producto específico
     */
    public function show(int $id): JsonResponse
    {
        try {
            $producto = $this->recetaService->getReceta($id);

            return $this->successResponse(
                data: $producto->recetas,
                message: 'Receta del producto'
            );
        } catch (\Exception $e) {
            return $this->errorResponse(
                message: 'Producto no encontrado o sin receta',
                code: 404
            );
        }
    }

    /**
     * Guardar o actualizar la receta de un producto
     */
    public function update(GuardarRecetaRequest $request, int $id): JsonResponse
    {
        try {
            $dto = GuardarRecetaDTO::fromRequest($request, $id);
            $producto = $this->recetaService->guardarReceta($dto);

            return $this->successResponse(
                data: $producto,
                message: 'Receta actualizada correctamente.'
            );
        } catch (InventarioException $e) {
            return $this->errorResponse(
                message: $e->getMessage(),
                code: 400
            );
        } catch (\Exception $e) {
            return $this->errorResponse(
                message: 'Error al actualizar receta: ' . $e->getMessage(),
                code: 500
            );
        }
    }
}
