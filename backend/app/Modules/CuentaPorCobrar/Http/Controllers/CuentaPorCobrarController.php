<?php
declare(strict_types=1);

namespace App\Modules\CuentaPorCobrar\Http\Controllers;

use App\Http\Controllers\Controller;
use App\Modules\CuentaPorCobrar\DTOs\RegistrarCobroDTO;
use App\Modules\CuentaPorCobrar\Http\Requests\RegistrarCobroRequest;
use App\Modules\CuentaPorCobrar\Services\CuentaPorCobrarService;
use App\Modules\Shared\Traits\ApiResponseTrait;
use App\Traits\HasIdempotency;
use Illuminate\Http\JsonResponse;

class CuentaPorCobrarController extends Controller
{
    use ApiResponseTrait;
    use HasIdempotency;

    public function __construct(
        private readonly CuentaPorCobrarService $cxcService
    ) {}

    public function index(): JsonResponse
    {
        $cxcs = $this->cxcService->getPending();
        return $this->successResponse(
            data: $cxcs,
            message: 'Lista de cuentas por cobrar pendientes'
        );
    }

    public function registrarPago(RegistrarCobroRequest $request, int $id): JsonResponse
    {
        // ── IDEMPOTENCIA ─────────────────────────────────────────────────────
        $cached = $this->checkIdempotency($request, 'cxc.pago');
        if ($cached) return $cached;
        // ─────────────────────────────────────────────────────────────────────

        try {
            $dto = RegistrarCobroDTO::fromRequest($request, $id);
            $pago = $this->cxcService->registrarCobro($dto);

            $responseData = ['pago' => $pago];
            return $this->saveIdempotency($request, 'cxc.pago', $responseData, 200, 'Cobro registrado con éxito');
        } catch (\Exception $e) {
            $this->failIdempotency($request, 'cxc.pago');
            return $this->errorResponse(
                message: 'Error al registrar el cobro: ' . $e->getMessage(),
                code: 400
            );
        }
    }

    public function historialPagos(): JsonResponse
    {
        $pagos = $this->cxcService->getHistorialPagos();
        return $this->successResponse(
            data: $pagos,
            message: 'Historial de cobros realizados'
        );
    }
}
