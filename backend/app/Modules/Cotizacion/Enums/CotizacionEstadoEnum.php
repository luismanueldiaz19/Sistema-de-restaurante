<?php

declare(strict_types=1);

namespace App\Modules\Cotizacion\Enums;

enum CotizacionEstadoEnum: string
{
    case PENDIENTE = 'pendiente';
    case APROBADO = 'aprobado';
    case CANCELADO = 'cancelado';

    public static function values(): array
    {
        return array_column(self::cases(), 'value');
    }
}
