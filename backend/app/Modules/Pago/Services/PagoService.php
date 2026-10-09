<?php
declare(strict_types=1);

namespace App\Modules\Pago\Services;

use App\Models\Pago;
use App\Modules\Pago\DTOs\RegistrarPagoDTO;
use Illuminate\Support\Facades\DB;

class PagoService
{
    public function registrarPago(RegistrarPagoDTO $dto): Pago
    {
        return DB::transaction(function () use ($dto) {
            $pago = Pago::create([
                'factura_id'      => $dto->factura_id,
                'user_id'         => auth()->id() ?? 1, // Usuario autenticado o fallback
                'caja_sesion_id'  => $dto->caja_sesion_id,
                'monto_pagado'    => $dto->monto_pagado,
                'monto_recibido'  => $dto->monto_recibido,
                'devuelta'        => $dto->devuelta,
                'metodo_pago'     => $dto->metodo_pago ?? 'efectivo',
                'metodo_pago_id'  => $dto->metodo_pago_id,
                'referencia_pago' => $dto->referencia_pago,
                'fecha_pago'      => $dto->fecha_pago,
            ]);

            return $pago;
        });
    }
}
