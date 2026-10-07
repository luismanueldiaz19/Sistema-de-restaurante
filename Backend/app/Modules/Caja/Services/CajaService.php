<?php

declare(strict_types=1);

namespace App\Modules\Caja\Services;

use App\Modules\Caja\DTOs\AperturaCajaDTO;
use App\Modules\Caja\Exceptions\CajaException;
use App\Models\CajaSesion;

class CajaService
{
    /**
     * Abrir una nueva sesión de caja modular
     */
    public function abrir(AperturaCajaDTO $dto): CajaSesion
    {
        // 1. Validar si ya existe una caja abierta para este usuario o esta caja física
        $existeAbierta = CajaSesion::where('estado', 'abierta')
            ->where(function ($query) use ($dto) {
                $query->where('caja_id', $dto->cajaId)
                      ->orWhere('user_id', $dto->userId);
            })
            ->exists();

        if ($existeAbierta) {
            throw new CajaException('Ya existe una sesión de caja abierta para esta caja o cajero.');
        }

        // 2. Persistencia
        return CajaSesion::create([
            'caja_id' => $dto->cajaId,
            'user_id' => $dto->userId,
            'turno_id' => $dto->turnoId,
            'monto_inicial' => $dto->montoInicial,
            'estado' => 'abierta',
            'fecha_apertura' => now(),
        ]);
    }
}
