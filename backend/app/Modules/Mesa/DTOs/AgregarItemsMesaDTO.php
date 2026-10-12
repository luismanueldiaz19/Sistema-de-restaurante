<?php

declare(strict_types=1);

namespace App\Modules\Mesa\DTOs;

use App\Modules\Mesa\Http\Requests\AgregarItemsMesaRequest;

final readonly class AgregarItemsMesaDTO
{
    /**
     * @param array<int, array{producto_id: int, nombre_producto: string, cantidad: float, precio_unitario: float}> $detalles
     */
    public function __construct(
        public array $detalles,
        public ?string $nota = null,
    ) {}

    public static function fromRequest(AgregarItemsMesaRequest $request): self
    {
        return new self(
            detalles: (array) $request->validated('detalles'),
            nota: $request->validated('nota'),
        );
    }
}
