<?php

declare(strict_types=1);

namespace App\Modules\Caja\DTOs;

use App\Modules\Caja\Http\Requests\CierreCajaRequest;

final readonly class CierreCajaDTO
{
    public function __construct(
        public float $montoFinalFisico,
        public array $desglose,
        public ?string $comentario,
        public int $userId
    ) {}

    public static function fromRequest(CierreCajaRequest $request): self
    {
        return new self(
            montoFinalFisico: (float) $request->validated('monto_final_fisico'),
            desglose: (array) ($request->validated('desglose') ?? []),
            comentario: $request->validated('comentario'),
            userId: (int) $request->user()->id
        );
    }
}
