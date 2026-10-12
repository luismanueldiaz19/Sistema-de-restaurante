<?php

declare(strict_types=1);

namespace App\Modules\Mesa\DTOs;

use App\Modules\Mesa\Http\Requests\UpdateMesaRequest;

final readonly class UpdateMesaDTO
{
    public function __construct(
        public ?string $nombre = null,
        public ?string $area = null,
        public ?int $capacidad = null,
        public ?string $estado = null,
    ) {}

    public static function fromRequest(UpdateMesaRequest $request): self
    {
        return new self(
            nombre: $request->has('nombre') ? (string) $request->validated('nombre') : null,
            area: $request->has('area') ? (string) $request->validated('area') : null,
            capacidad: $request->has('capacidad') ? (int) $request->validated('capacidad') : null,
            estado: $request->has('estado') ? (string) $request->validated('estado') : null,
        );
    }

    public function toArray(): array
    {
        return array_filter([
            'nombre'    => $this->nombre,
            'area'      => $this->area,
            'capacidad' => $this->capacidad,
            'estado'    => $this->estado,
        ], fn($v) => !is_null($v));
    }
}
