<?php

declare(strict_types=1);

namespace App\Modules\Inventario\DTOs;

use App\Modules\Inventario\Http\Requests\GuardarRecetaRequest;

final readonly class GuardarRecetaDTO
{
    /**
     * @param array<array{ingrediente_producto_id: int, cantidad: float}> $ingredientes
     */
    public function __construct(
        public int $productoId,
        public array $ingredientes
    ) {}

    public static function fromRequest(GuardarRecetaRequest $request, int $productoId): self
    {
        return new self(
            productoId: $productoId,
            ingredientes: (array) $request->validated('ingredientes', [])
        );
    }
}
