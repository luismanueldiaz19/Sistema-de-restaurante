<?php

declare(strict_types=1);

namespace App\Modules\Mesa\Http\Controllers;

use App\Http\Controllers\Controller;
use App\Modules\Mesa\DTOs\AbrirMesaDTO;
use App\Modules\Mesa\DTOs\AgregarItemsMesaDTO;
use App\Modules\Mesa\DTOs\CreateMesaDTO;
use App\Modules\Mesa\DTOs\UpdateMesaDTO;
use App\Modules\Mesa\Http\Requests\AbrirMesaRequest;
use App\Modules\Mesa\Http\Requests\AgregarItemsMesaRequest;
use App\Modules\Mesa\Http\Requests\StoreMesaRequest;
use App\Modules\Mesa\Http\Requests\UpdateMesaRequest;
use App\Modules\Mesa\Services\MesaService;
use App\Modules\Shared\Traits\ApiResponseTrait;
use Exception;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class MesaController extends Controller
{
    use ApiResponseTrait;

    public function __construct(
        private readonly MesaService $mesaService
    ) {}

    public function index(Request $request): JsonResponse
    {
        try {
            $area = $request->query('area');
            $mesas = $this->mesaService->getAll($area);
            $areas = $this->mesaService->getAreas();

            return response()->json([
                'success' => true,
                'message' => 'Lista de mesas',
                'data'    => $mesas,
                'areas'   => $areas,
            ]);
        } catch (Exception $e) {
            return $this->errorResponse('Error al obtener mesas: ' . $e->getMessage(), 500);
        }
    }

    public function show(int $id): JsonResponse
    {
        try {
            $mesa = $this->mesaService->findById($id);
            if (!$mesa) {
                return $this->errorResponse('Mesa no encontrada', 404);
            }

            return $this->successResponse($mesa, 'Detalle de mesa');
        } catch (Exception $e) {
            return $this->errorResponse('Error: ' . $e->getMessage(), 500);
        }
    }

    public function store(StoreMesaRequest $request): JsonResponse
    {
        try {
            $dto = CreateMesaDTO::fromRequest($request);
            $mesa = $this->mesaService->create($dto);
            return $this->successResponse($mesa, 'Mesa creada exitosamente', 201);
        } catch (Exception $e) {
            return $this->errorResponse('Error al crear la mesa: ' . $e->getMessage(), 500);
        }
    }

    public function update(UpdateMesaRequest $request, int $id): JsonResponse
    {
        try {
            $dto = UpdateMesaDTO::fromRequest($request);
            $mesa = $this->mesaService->update($id, $dto);
            return $this->successResponse($mesa, 'Mesa actualizada exitosamente');
        } catch (Exception $e) {
            return $this->errorResponse('Error al actualizar la mesa: ' . $e->getMessage(), 400);
        }
    }

    public function destroy(Request $request, int $id): JsonResponse
    {
        try {
            $user = $request->user();
            if ($user && !$user->hasRole('admin')) {
                return $this->errorResponse('Solo un administrador del sistema puede eliminar mesas.', 403);
            }

            $this->mesaService->delete($id);
            return $this->successResponse(null, 'Mesa eliminada exitosamente');
        } catch (Exception $e) {
            return $this->errorResponse($e->getMessage(), 400);
        }
    }

    public function abrir(AbrirMesaRequest $request, int $id): JsonResponse
    {
        try {
            $dto = AbrirMesaDTO::fromRequest($request);
            $mesa = $this->mesaService->abrirMesa($id, $dto);
            return $this->successResponse($mesa, 'Mesa abierta y comanda creada exitosamente', 201);
        } catch (Exception $e) {
            return $this->errorResponse($e->getMessage(), 400);
        }
    }

    public function agregarItems(AgregarItemsMesaRequest $request, int $id): JsonResponse
    {
        try {
            $dto = AgregarItemsMesaDTO::fromRequest($request);
            $mesa = $this->mesaService->agregarItems($id, $dto);
            return $this->successResponse($mesa, 'Artículos agregados a la comanda de la mesa');
        } catch (Exception $e) {
            return $this->errorResponse($e->getMessage(), 400);
        }
    }

    public function solicitarCuenta(int $id): JsonResponse
    {
        try {
            $mesa = $this->mesaService->solicitarCuenta($id);
            return $this->successResponse($mesa, 'Estado de la mesa cambiado a Por Cobrar');
        } catch (Exception $e) {
            return $this->errorResponse($e->getMessage(), 400);
        }
    }

    public function liberar(Request $request, int $id): JsonResponse
    {
        try {
            $user = $request->user();
            $porFactura = $request->boolean('por_factura');

            $esAdmin = $user && $user->hasRole('admin');
            $esFacturacion = $porFactura && $user && ($user->hasRole('admin') || $user->hasRole('cajero') || $user->hasRole('vendedor'));

            if (!$esAdmin && !$esFacturacion) {
                return $this->errorResponse('Solo un administrador del sistema puede liberar mesas directamente.', 403);
            }

            $mesa = $this->mesaService->liberarMesa($id);
            return $this->successResponse($mesa, 'Mesa liberada exitosamente');
        } catch (Exception $e) {
            return $this->errorResponse($e->getMessage(), 400);
        }
    }

    public function areas(): JsonResponse
    {
        try {
            $areas = $this->mesaService->getAreas();
            return $this->successResponse($areas, 'Lista de áreas');
        } catch (Exception $e) {
            return $this->errorResponse('Error: ' . $e->getMessage(), 500);
        }
    }
}
