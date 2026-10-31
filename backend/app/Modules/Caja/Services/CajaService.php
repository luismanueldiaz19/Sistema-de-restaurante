<?php

declare(strict_types=1);

namespace App\Modules\Caja\Services;

use App\Models\Caja;
use App\Models\CajaSesion;
use App\Models\Turno;
use App\Modules\Caja\DTOs\AperturaCajaDTO;
use App\Modules\Caja\DTOs\CierreCajaDTO;
use App\Modules\Caja\Exceptions\CajaException;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;
use Illuminate\Database\Eloquent\Collection;
use Illuminate\Support\Facades\DB;

class CajaService
{
    /**
     * Obtener listado de cajas físicas activas
     */
    public function getCajas(): Collection
    {
        return Caja::where('activa', true)->get();
    }

    /**
     * Obtener listado de turnos
     */
    public function getTurnos(): Collection
    {
        return Turno::all();
    }

    /**
     * Obtener la sesión activa de caja para un usuario específico
     */
    public function getSesionActiva(int $userId): ?CajaSesion
    {
        return CajaSesion::with(['caja', 'turno', 'usuario'])
            ->where('user_id', $userId)
            ->where('estado', 'abierta')
            ->first();
    }

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
        $sesion = CajaSesion::create([
            'caja_id' => $dto->cajaId,
            'user_id' => $dto->userId,
            'turno_id' => $dto->turnoId,
            'monto_inicial' => $dto->montoInicial,
            'estado' => 'abierta',
            'fecha_apertura' => now(),
        ]);

        return $sesion->fresh(['caja', 'turno', 'usuario']);
    }

    /**
     * Obtener resumen de ventas preliminar antes de cerrar la caja
     */
    public function getResumenCierre(int $sesionId): array
    {
        $sesion = CajaSesion::findOrFail($sesionId);

        // 1. Ventas por Método de Pago en la sesión
        $pagos = DB::table('pagos')
            ->where('caja_sesion_id', $sesionId)
            ->select('metodo_pago', DB::raw('SUM(monto_pagado) as total'), DB::raw('COUNT(*) as cantidad'))
            ->groupBy('metodo_pago')
            ->get();

        // 2. Totales Generales de Facturación
        $totales = DB::table('facturas')
            ->where('caja_sesion_id', $sesionId)
            ->selectRaw('COUNT(*) as cantidad_facturas, SUM(total) as total_venta, SUM(itbis) as total_itbis, SUM(descuento_total) as total_descuento')
            ->first();

        // 3. Ventas por Tipo (Contado vs Crédito)
        $porTipo = DB::table('facturas')
            ->where('caja_sesion_id', $sesionId)
            ->select('tipo_factura', DB::raw('SUM(total) as total'))
            ->groupBy('tipo_factura')
            ->get();

        $efectivoVendido = (float) ($pagos->where('metodo_pago', 'efectivo')->first()->total ?? 0);
        $montoInicial = (float) $sesion->monto_inicial;

        return [
            'monto_inicial' => $montoInicial,
            'ventas_por_metodo' => $pagos,
            'ventas_por_tipo' => $porTipo,
            'totales_generales' => [
                'cantidad_facturas' => (int) ($totales->cantidad_facturas ?? 0),
                'total_venta' => (float) ($totales->total_venta ?? 0),
                'total_itbis' => (float) ($totales->total_itbis ?? 0),
                'total_descuento' => (float) ($totales->total_descuento ?? 0),
            ],
            'monto_esperado_efectivo' => $montoInicial + $efectivoVendido,
            'fecha_apertura' => $sesion->fecha_apertura,
        ];
    }

    /**
     * Cerrar sesión de caja activa con arqueo y conteo físico
     */
    public function cerrar(CierreCajaDTO $dto): CajaSesion
    {
        $sesion = CajaSesion::where('user_id', $dto->userId)
            ->where('estado', 'abierta')
            ->first();

        if (!$sesion) {
            throw new CajaException('No tienes una sesión de caja abierta para cerrar.');
        }

        // 1. Calcular efectivo esperado: Monto Inicial + Pagos en Efectivo
        $efectivoVentas = (float) DB::table('pagos')
            ->where('caja_sesion_id', $sesion->id)
            ->where('metodo_pago', 'efectivo')
            ->sum('monto_pagado');

        $montoEsperado = (float) $sesion->monto_inicial + $efectivoVentas;
        $diferencia = $dto->montoFinalFisico - $montoEsperado;

        // 2. Resumen de ventas agrupado por método de pago para auditoría histórica
        $resumenVentas = DB::table('pagos')
            ->where('caja_sesion_id', $sesion->id)
            ->select('metodo_pago', DB::raw('SUM(monto_pagado) as total'))
            ->groupBy('metodo_pago')
            ->get();

        // 3. Actualizar y cerrar la sesión
        $sesion->update([
            'monto_final_esperado' => $montoEsperado,
            'monto_final_fisico'   => $dto->montoFinalFisico,
            'diferencia'           => $diferencia,
            'desglose_efectivo'    => $dto->desglose,
            'resumen_ventas'       => $resumenVentas,
            'estado'               => 'cerrada',
            'fecha_cierre'         => now(),
            'comentario'           => $dto->comentario,
        ]);

        return $sesion->fresh(['caja', 'turno', 'usuario']);
    }

    /**
     * Obtener el historial de sesiones de caja con filtros
     */
    public function getHistorial(array $filters = [], int $currentUserId = 0, bool $isAdmin = false): LengthAwarePaginator
    {
        $query = CajaSesion::with(['caja', 'turno', 'usuario'])
            ->withCount('facturas')
            ->orderBy('fecha_apertura', 'desc');

        if (!$isAdmin && $currentUserId > 0) {
            $query->where('user_id', $currentUserId);
        } elseif (!empty($filters['user_id'])) {
            $query->where('user_id', $filters['user_id']);
        }

        if (!empty($filters['fecha_desde'])) {
            $query->where('fecha_apertura', '>=', $filters['fecha_desde'] . ' 00:00:00');
        }

        if (!empty($filters['fecha_hasta'])) {
            $query->where('fecha_apertura', '<=', $filters['fecha_hasta'] . ' 23:59:59');
        }

        if (!empty($filters['estado'])) {
            $query->where('estado', $filters['estado']);
        }

        if (!empty($filters['caja_id'])) {
            $query->where('caja_id', $filters['caja_id']);
        }

        if (!empty($filters['search'])) {
            $search = trim($filters['search']);
            $query->where(function ($q) use ($search) {
                if (is_numeric($search)) {
                    $q->where('id', $search);
                }
                $q->orWhere('comentario', 'like', "%{$search}%")
                  ->orWhereHas('caja', function ($cq) use ($search) {
                      $cq->where('nombre', 'like', "%{$search}%");
                  })
                  ->orWhereHas('usuario', function ($uq) use ($search) {
                      $uq->where('name', 'like', "%{$search}%");
                  })
                  ->orWhereHas('turno', function ($tq) use ($search) {
                      $tq->where('nombre', 'like', "%{$search}%");
                  });
            });
        }

        $perPage = (int) ($filters['per_page'] ?? 15);
        $page = !empty($filters['page']) ? (int) $filters['page'] : null;

        return $query->paginate(perPage: $perPage, page: $page);
    }
}
