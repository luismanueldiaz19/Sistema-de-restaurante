<?php

declare(strict_types=1);

namespace App\Modules\Compra\Enums;

enum CompraTipoEnum: string
{
    case CONTADO = 'CONTADO';
    case CREDITO = 'CREDITO';

    public static function values(): array
    {
        return array_column(self::cases(), 'value');
    }
}
