<?php

declare(strict_types=1);

namespace App\Modules\Caja\Http\Controllers;

use App\Http\Controllers\Controller;
use App\Modules\Caja\DTOs\AperturaCajaDTO;
use App\Modules\Caja\Http\Requests\AperturaCajaRequest;
use App\Modules\Caja\Services\CajaService;
use App\Modules\Shared\Traits\ApiResponseTrait;
use Illuminate\Http\JsonResponse;

class CajaController extends Controller
{
    use ApiResponseTrait;

    public function __construct(
        private readonly CajaService $cajaService
    ) {}

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
                code: $e->getCode() >= 400 ? $e->getCode() : 500
            );
        }
    }
}
