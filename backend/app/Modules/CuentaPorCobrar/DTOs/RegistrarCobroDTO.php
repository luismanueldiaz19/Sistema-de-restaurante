<?php
declare(strict_types=1);

namespace App\Modules\CuentaPorCobrar\DTOs;

use Illuminate\Http\Request;

class RegistrarCobroDTO
{
    public function __construct(
        public readonly int $cxc_id,
        public readonly float $monto_pagado,
        public readonly string $fecha_pago,
        public readonly int $metodo_pago_id,
        public readonly ?string $referencia = null
    ) {}

    public static function fromRequest(Request $request, int $cxc_id): self
    {
        return new self(
            cxc_id: $cxc_id,
            monto_pagado: (float) $request->input('monto_pagado'),
            fecha_pago: $request->input('fecha_pago', now()->toDateString()),
            metodo_pago_id: (int) $request->input('metodo_pago_id'),
            referencia: $request->input('referencia')
        );
    }
}
