<?php

declare(strict_types=1);

namespace App\Modules\Producto\Enums;

enum TipoProductoEnum: string
{
    case PRODUCTO = 'PRODUCTO';
    case SERVICIO = 'SERVICIO';
    case COMBO = 'COMBO';
    case MATERIA_PRIMA = 'MATERIA_PRIMA';
    case PLATO = 'PLATO';
}
