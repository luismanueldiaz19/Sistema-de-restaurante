<?php

declare(strict_types=1);

namespace App\Modules\Caja\Http\Controllers;

use App\Http\Controllers\Controller;
use App\Modules\Caja\DTOs\AperturaCajaDTO;
use App\Modules\Caja\DTOs\CierreCajaDTO;
use App\Modules\Caja\Http\Requests\AperturaCajaRequest;
use App\Modules\Caja\Http\Requests\CierreCajaRequest;
use App\Modules\Caja\Services\CajaService;
use App\Modules\Shared\Traits\ApiResponseTrait;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class CajaController extends Controller
{
    use ApiResponseTrait;

    public function __construct(
        private readonly CajaService $cajaService
    ) {}

    /**
     * Listado de cajas físicas activas
     */
    public function index(): JsonResponse
    {
        return $this->successResponse(
            data: $this->cajaService->getCajas(),
            message: 'Cajas físicas obtenidas exitosamente'
        );
    }

    /**
     * Listado de turnos de trabajo
     */
    public function turnos(): JsonResponse
    {
        return $this->successResponse(
            data: $this->cajaService->getTurnos(),
            message: 'Turnos obtenidos exitosamente'
        );
    }

    /**
     * Obtener el estado actual de la caja para el usuario autenticado
     */
    public function estadoActual(Request $request): JsonResponse
    {
        $sesion = $this->cajaService->getSesionActiva((int) $request->user()->id);

        return $this->successResponse(
            data: $sesion,
            message: $sesion ? 'Sesión activa encontrada' : 'No hay sesión activa'
        );
    }

    /**
     * Apertura de una nueva sesión de caja
     */
    public function abrir(AperturaCajaRequest $request): JsonResponse
    {
        try {
            $dto = AperturaCajaDTO::fromRequest($request);
            $sesion = $this->cajaService->abrir($dto);

            return $this->successResponse(
                data: $sesion,
                message: 'Caja abierta exitosamente',
                code: 201
            );
        } catch (\Exception $e) {
            return $this->errorResponse(
                message: $e->getMessage(),
                code: $e->getCode() >= 400 && $e->getCode() <= 500 ? (int) $e->getCode() : 400
            );
        }
    }

    /**
     * Obtener el resumen de ventas y efectivo esperado antes del cierre
     */
    public function resumen(Request $request): JsonResponse
    {
        try {
            $sesion = $this->cajaService->getSesionActiva((int) $request->user()->id);
            if (!$sesion) {
                return $this->errorResponse('No hay sesión activa de caja para este usuario', 404);
            }

            $resumen = $this->cajaService->getResumenCierre((int) $sesion->id);

            return $this->successResponse(
                data: $resumen,
                message: 'Resumen de cierre obtenido exitosamente'
            );
        } catch (\Exception $e) {
            return $this->errorResponse(
                message: $e->getMessage(),
                code: 400
            );
        }
    }

    /**
     * Cerrar la sesión de caja activa con arqueo físico
     */
    public function cerrar(CierreCajaRequest $request): JsonResponse
    {
        try {
            $dto = CierreCajaDTO::fromRequest($request);
            $sesion = $this->cajaService->cerrar($dto);

            return $this->successResponse(
                data: $sesion,
                message: 'Caja cerrada exitosamente'
            );
        } catch (\Exception $e) {
            return $this->errorResponse(
                message: $e->getMessage(),
                code: 400
            );
        }
    }

    /**
     * Historial de sesiones de caja con filtros y paginación
     */
    public function historial(Request $request): JsonResponse
    {
        try {
            $filters = $request->only(['fecha_desde', 'fecha_hasta', 'user_id', 'estado', 'caja_id', 'per_page', 'page', 'search']);
            $isAdmin = method_exists($request->user(), 'hasRole') ? $request->user()->hasRole('admin') : false;

            $historial = $this->cajaService->getHistorial(
                filters: $filters,
                currentUserId: (int) $request->user()->id,
                isAdmin: $isAdmin
            );

            return $this->successResponse(
                data: $historial,
                message: 'Historial de sesiones obtenido exitosamente'
            );
        } catch (\Exception $e) {
            return $this->errorResponse(
                message: $e->getMessage(),
                code: 400
            );
        }
    }
}
