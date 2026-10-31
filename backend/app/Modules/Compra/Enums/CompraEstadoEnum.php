<?php

declare(strict_types=1);

namespace App\Modules\Compra\Enums;

enum CompraEstadoEnum: string
{
    case PENDIENTE = 'PENDIENTE';
    case PAGADA = 'PAGADA';
    case CANCELADA = 'CANCELADA';

    public static function values(): array
    {
        return array_column(self::cases(), 'value');
    }
}
