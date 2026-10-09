<?php
declare(strict_types=1);

namespace App\Modules\Pago\Http\Controllers;

use App\Http\Controllers\Controller;
use App\Modules\Pago\DTOs\RegistrarPagoDTO;
use App\Modules\Pago\Http\Requests\RegistrarPagoRequest;
use App\Modules\Pago\Services\PagoService;
use App\Modules\Shared\Traits\ApiResponseTrait;
use App\Traits\HasIdempotency;
use Illuminate\Http\JsonResponse;

class PagoController extends Controller
{
    use ApiResponseTrait;
    use HasIdempotency;

    public function __construct(
        private readonly PagoService $pagoService
    ) {}

    public function registrarPago(RegistrarPagoRequest $request, int $factura_id): JsonResponse
    {
        // ── IDEMPOTENCIA ─────────────────────────────────────────────────────
        $cached = $this->checkIdempotency($request, 'factura.pago');
        if ($cached) return $cached;
        // ─────────────────────────────────────────────────────────────────────

        try {
            $dto = RegistrarPagoDTO::fromRequest($request, $factura_id);
            $pago = $this->pagoService->registrarPago($dto);

            $responseData = ['pago' => $pago];
            return $this->saveIdempotency($request, 'factura.pago', $responseData, 201, 'Pago de factura registrado con éxito');
        } catch (\Exception $e) {
            $this->failIdempotency($request, 'factura.pago');
            return $this->errorResponse(
                message: 'Error al registrar el pago: ' . $e->getMessage(),
                code: 400
            );
        }
    }
}
