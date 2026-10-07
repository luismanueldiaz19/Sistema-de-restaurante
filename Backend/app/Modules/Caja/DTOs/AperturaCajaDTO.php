<?php

declare(strict_types=1);

namespace App\Modules\Caja\DTOs;

use App\Modules\Caja\Http\Requests\AperturaCajaRequest;

final readonly class AperturaCajaDTO
{
    public function __construct(
        public int $cajaId,
        public int $turnoId,
        public float $montoInicial,
        public int $userId
    ) {}

    public static function fromRequest(AperturaCajaRequest $request): self
    {
        return new self(
            cajaId: (int) $request->validated('caja_id'),
            turnoId: (int) $request->validated('turno_id'),
            montoInicial: (float) $request->validated('monto_inicial'),
            userId: $request->user()->id
        );
    }
}
