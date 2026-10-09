<?php
declare(strict_types=1);

namespace App\Modules\Contabilidad\DTOs;

class RegistrarAsientoDTO
{
    public function __construct(
        public readonly string $tipo_transaccion,
        public readonly float $subtotal,
        public readonly float $itbis,
        public readonly float $total,
        public readonly string $referencia,
        public readonly string $glosa,
        public readonly ?int $usuario_id = null,
        public readonly array $custom_configs = [],
        public readonly float $costo = 0.0
    ) {}
}
