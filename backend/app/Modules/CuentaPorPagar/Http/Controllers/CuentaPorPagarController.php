<?php

declare(strict_types=1);

namespace App\Modules\CuentaPorPagar\Http\Controllers;

use App\Http\Controllers\Controller;
use App\Modules\CuentaPorPagar\DTOs\RegistrarPagoDTO;
use App\Modules\CuentaPorPagar\Http\Requests\RegistrarPagoRequest;
use App\Modules\CuentaPorPagar\Services\CuentaPorPagarService;
use App\Modules\Shared\Traits\ApiResponseTrait;
use App\Traits\HasIdempotency;
use Illuminate\Http\JsonResponse;

class CuentaPorPagarController extends Controller
{
    use ApiResponseTrait;
    use HasIdempotency;

    public function __construct(
        private readonly CuentaPorPagarService $cuentaPorPagarService
    ) {}

    public function index(): JsonResponse
    {
        $cxps = $this->cuentaPorPagarService->getPending();

        return $this->successResponse(
            data: $cxps,
            message: 'Lista de cuentas por pagar pendientes'
        );
    }

    public function registrarPago(RegistrarPagoRequest $request, int $id): JsonResponse
    {
        // ── IDEMPOTENCIA ─────────────────────────────────────────────────────
        $cached = $this->checkIdempotency($request, 'cxp.pago');
        if ($cached) return $cached;
        // ─────────────────────────────────────────────────────────────────────

        try {
            $dto = RegistrarPagoDTO::fromRequest($request, $id);
            $pago = $this->cuentaPorPagarService->registrarPago($dto);

            $responseData = ['pago' => $pago];
            return $this->saveIdempotency($request, 'cxp.pago', $responseData, 200, 'Pago registrado con éxito');
        } catch (\Exception $e) {
            $this->failIdempotency($request, 'cxp.pago');
            return $this->errorResponse(
                message: 'Error al registrar el abono: ' . $e->getMessage(),
                code: 400
            );
        }
    }

    public function historialPagos(\Illuminate\Http\Request $request): JsonResponse
    {
        $filters = $request->all();
        if (!empty($filters['search'])) {
            $filters['search'] = $this->normalizarTexto($filters['search']);
        }

        $pagos = $this->cuentaPorPagarService->getHistorialPagos($filters);

        return $this->successResponse(
            data: $pagos,
            message: 'Historial de pagos de compras'
        );
    }

    public function pagosPorCompra(int $compraId): JsonResponse
    {
        $pagos = $this->cuentaPorPagarService->getPagosPorCompra($compraId);

        return $this->successResponse(
            data: $pagos,
            message: 'Pagos de la compra seleccionada'
        );
    }
}
