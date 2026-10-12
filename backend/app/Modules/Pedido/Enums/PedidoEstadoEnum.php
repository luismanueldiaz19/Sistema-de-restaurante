<?php

declare(strict_types=1);

namespace App\Modules\Pedido\Enums;

enum PedidoEstadoEnum: string
{
    case PENDIENTE = 'Pendiente';
    case CONFIRMADO = 'Confirmado';
    case PREPARANDO = 'Preparando';
    case FACTURADO = 'Facturado';
    case CANCELADO = 'Cancelado';

    public static function values(): array
    {
        return array_column(self::cases(), 'value');
    }
}
