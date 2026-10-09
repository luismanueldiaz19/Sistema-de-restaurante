<?php
declare(strict_types=1);

namespace App\Modules\CuentaPorPagar\DTOs;

use Illuminate\Http\Request;

class RegistrarPagoDTO
{
    public function __construct(
        public readonly int $cxp_id,
        public readonly float $monto_pagado,
        public readonly string $fecha_pago,
        public readonly int $metodo_pago_id,
        public readonly ?string $referencia,
        public readonly ?string $idempotency_key,
    ) {}

    public static function fromRequest(Request $request, int $cxp_id): self
    {
        return new self(
            cxp_id: $cxp_id,
            monto_pagado: (float) $request->input('monto_pagado'),
            fecha_pago: $request->input('fecha_pago'),
            metodo_pago_id: (int) $request->input('metodo_pago_id'),
            referencia: $request->input('referencia'),
            idempotency_key: $request->input('idempotency_key'),
        );
    }
}
