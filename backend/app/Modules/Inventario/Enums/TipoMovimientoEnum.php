<?php

declare(strict_types=1);

namespace App\Modules\Inventario\Enums;

enum TipoMovimientoEnum: string
{
    case ENTRADA = 'ENTRADA';
    case SALIDA  = 'SALIDA';
}
