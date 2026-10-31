<?php

declare(strict_types=1);

namespace App\Modules\Producto\Enums;

enum TipoContableEnum: string
{
    case INVENTARIO = 'INVENTARIO';
    case GASTO = 'GASTO';
    case ACTIVO_FIJO = 'ACTIVO_FIJO';
    case SERVICIO = 'SERVICIO';
}
