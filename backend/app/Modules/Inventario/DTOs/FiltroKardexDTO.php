<?php

declare(strict_types=1);

namespace App\Modules\Inventario\DTOs;

use Illuminate\Http\Request;

final readonly class FiltroKardexDTO
{
    public function __construct(
        public ?int $productoId = null,
        public ?string $tipo = null,
        public ?string $fechaDesde = null,
        public ?string $fechaHasta = null,
        public ?string $search = null,
        public int $perPage = 15
    ) {}

    public static function fromRequest(Request $request): self
    {
        return new self(
            productoId: $request->filled('producto_id') ? (int) $request->input('producto_id') : null,
            tipo: $request->filled('tipo') ? (string) $request->input('tipo') : null,
            fechaDesde: $request->filled('fecha_desde') ? (string) $request->input('fecha_desde') : null,
            fechaHasta: $request->filled('fecha_hasta') ? (string) $request->input('fecha_hasta') : null,
            search: $request->filled('search') ? (string) $request->input('search') : null,
            perPage: $request->filled('per_page') ? (int) $request->input('per_page') : 15
        );
    }
}
