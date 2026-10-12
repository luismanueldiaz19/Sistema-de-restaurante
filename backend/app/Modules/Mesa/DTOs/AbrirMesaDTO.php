<?php

declare(strict_types=1);

namespace App\Modules\Mesa\DTOs;

use App\Modules\Mesa\Http\Requests\AbrirMesaRequest;

final readonly class AbrirMesaDTO
{
    public function __construct(
        public ?string $clienteNombre,
        public ?string $clienteTelefono,
        public ?string $mesero,
        public ?string $nota,
        public array $detalles,
    ) {}

    public static function fromRequest(AbrirMesaRequest $request): self
    {
        return new self(
            clienteNombre: $request->validated('cliente_nombre'),
            clienteTelefono: $request->validated('cliente_telefono'),
            mesero: $request->validated('mesero'),
            nota: $request->validated('nota'),
            detalles: (array) $request->validated('detalles'),
        );
    }
}
