<?php

namespace App\Services;

use App\Models\CajaSesion;
use App\Models\Factura;
use Exception;
use Illuminate\Support\Facades\DB;

class CajaService
{
    /**
     * Abrir una nueva sesión de caja
     */
    public function abrirCaja(array $data)
    {
        // 1. Validar si ya existe una caja abierta para este usuario o esta caja física
        $existeAbierta = CajaSesion::where('estado', 'abierta')
            ->where(function ($query) use ($data) {
                $query->where('caja_id', $data['caja_id'])
                      ->orWhere('user_id', $data['user_id']);
            })
            ->exists();

        if ($existeAbierta) {
            throw new Exception('Ya existe una sesión de caja abierta para esta caja o cajero.');
        }

        return CajaSesion::create([
            'caja_id' => $data['caja_id'],
            'user_id' => $data['user_id'],
            'turno_id' => $data['turno_id'],
            'monto_inicial' => $data['monto_inicial'],
            'estado' => 'abierta',
            'fecha_apertura' => now(),
        ]);
    }

    /**
     * Cerrar una sesión de caja activa
     */
    public function cerrarCaja(int $sesionId, float $montoFisico, string $comentario = null)
    {
        $sesion = CajaSesion::findOrFail($sesionId);

        if ($sesion->estado !== 'abierta') {
            throw new Exception('Esta sesión de caja ya se encuentra cerrada.');
        }

        // 1. Calcular el monto esperado (Monto Inicial + Ventas Pagadas)
        $ventasTotales = Factura::where('caja_sesion_id', $sesionId)
            ->where('estado', 'pagada')
            ->sum('total');

        $montoEsperado = $sesion->monto_inicial + $ventasTotales;
        $diferencia = $montoFisico - $montoEsperado;

        $sesion->update([
            'monto_final_esperado' => $montoEsperado,
            'monto_final_fisico' => $montoFisico,
            'diferencia' => $diferencia,
            'estado' => 'cerrada',
            'fecha_cierre' => now(),
            'comentario' => $comentario
        ]);

        return $sesion;
    }

    /**
     * Obtener la sesión activa de un usuario
     */
    public function getSesionActiva(int $userId)
    {
        return CajaSesion::with(['caja', 'turno'])
            ->where('user_id', $userId)
            ->where('estado', 'abierta')
            ->first();
    }
}
