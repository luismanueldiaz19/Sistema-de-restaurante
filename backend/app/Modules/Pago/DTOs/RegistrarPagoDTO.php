<?php
declare(strict_types=1);

namespace App\Modules\Pago\DTOs;

use Illuminate\Http\Request;

class RegistrarPagoDTO
{
    public function __construct(
        public readonly int $factura_id,
        public readonly float $monto_pagado,
        public readonly float $monto_recibido,
        public readonly float $devuelta,
        public readonly ?string $metodo_pago,
        public readonly ?int $metodo_pago_id,
        public readonly ?string $referencia_pago,
        public readonly string $fecha_pago,
        public readonly ?int $caja_sesion_id = null
    ) {}

    public static function fromRequest(Request $request, int $factura_id): self
    {
        return new self(
            factura_id: $factura_id,
            monto_pagado: (float) $request->input('monto_pagado'),
            monto_recibido: (float) $request->input('monto_recibido', $request->input('monto_pagado')),
            devuelta: (float) $request->input('devuelta', 0),
            metodo_pago: $request->input('metodo_pago', 'efectivo'),
            metodo_pago_id: $request->input('metodo_pago_id') ? (int) $request->input('metodo_pago_id') : null,
            referencia_pago: $request->input('referencia_pago'),
            fecha_pago: $request->input('fecha_pago', now()->toDateString()),
            caja_sesion_id: $request->input('caja_sesion_id') ? (int) $request->input('caja_sesion_id') : null
        );
    }
}
