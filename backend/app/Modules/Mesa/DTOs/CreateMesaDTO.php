<?php

declare(strict_types=1);

namespace App\Modules\Mesa\DTOs;

use App\Modules\Mesa\Http\Requests\StoreMesaRequest;

final readonly class CreateMesaDTO
{
    public function __construct(
        public string $nombre,
        public string $area = 'Principal',
        public int $capacidad = 4,
    ) {}

    public static function fromRequest(StoreMesaRequest $request): self
    {
        return new self(
            nombre: (string) $request->validated('nombre'),
            area: (string) ($request->validated('area') ?? 'Principal'),
            capacidad: (int) ($request->validated('capacidad') ?? 4),
        );
    }

    public function toArray(): array
    {
        return [
            'nombre'    => $this->nombre,
            'area'      => $this->area,
            'capacidad' => $this->capacidad,
            'estado'    => 'Libre',
        ];
    }
}
