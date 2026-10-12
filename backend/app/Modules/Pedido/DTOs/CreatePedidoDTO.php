<?php

declare(strict_types=1);

namespace App\Modules\Pedido\DTOs;

use App\Modules\Pedido\Http\Requests\StorePedidoRequest;

final readonly class CreatePedidoDTO
{
    public function __construct(
        public string $clienteNombre,
        public ?string $clienteTelefono,
        public ?string $direccion,
        public string $tipoEntrega,
        public ?string $nota,
        public ?string $fecha,
        public float $total,
        public array $detalles,
        public ?int $usuarioId = null,
    ) {}

    public static function fromRequest(StorePedidoRequest $request): self
    {
        return new self(
            clienteNombre: (string) $request->validated('cliente_nombre'),
            clienteTelefono: $request->validated('cliente_telefono'),
            direccion: $request->validated('direccion'),
            tipoEntrega: $request->validated('tipo_entrega') === 'Delivery' ? 'Domicilio' : (string) $request->validated('tipo_entrega'),
            nota: $request->validated('nota'),
            fecha: $request->validated('fecha') ?? date('Y-m-d'),
            total: (float) ($request->validated('total') ?? 0),
            detalles: (array) $request->validated('detalles'),
            usuarioId: $request->user()?->id,
        );
    }
}
