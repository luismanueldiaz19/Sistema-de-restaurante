<?php

declare(strict_types=1);

namespace App\Modules\Pedido\Enums;

enum PedidoTipoEntregaEnum: string
{
    case DOMICILIO = 'Domicilio';
    case RECOGER = 'Recoger';
    case LOCAL = 'Local';

    public static function values(): array
    {
        return array_column(self::cases(), 'value');
    }
}
