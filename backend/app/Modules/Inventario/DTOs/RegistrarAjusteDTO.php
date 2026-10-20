<?php

declare(strict_types=1);

namespace App\Modules\Inventario\DTOs;

use App\Modules\Inventario\Enums\TipoMovimientoEnum;
use App\Modules\Inventario\Http\Requests\RegistrarAjusteRequest;

final readonly class RegistrarAjusteDTO
{
    public function __construct(
        public int $productoId,
        public TipoMovimientoEnum $tipo,
        public float $cantidad,
        public string $motivo,
        public ?int $usuarioId = null
    ) {}

    public static function fromRequest(RegistrarAjusteRequest $request): self
    {
        return new self(
            productoId: (int) $request->validated('producto_id'),
            tipo: TipoMovimientoEnum::from((string) $request->validated('tipo')),
            cantidad: (float) $request->validated('cantidad'),
            motivo: (string) $request->validated('motivo'),
            usuarioId: $request->user()?->id
        );
    }
}
