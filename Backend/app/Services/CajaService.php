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
    public function cerrarCaja(int $sesionId, float $montoFisico, array $desglose = [], string $comentario = null)
    {
        $sesion = CajaSesion::findOrFail($sesionId);

        if ($sesion->estado !== 'abierta') {
            throw new Exception('Esta sesión de caja ya se encuentra cerrada.');
        }

        // 1. Calcular el monto esperado en EFECTIVO (Monto Inicial + Pagos en Efectivo)
        $efectivoVentas = DB::table('pagos')
            ->where('caja_sesion_id', $sesionId)
            ->where('metodo_pago', 'efectivo')
            ->sum('monto_pagado');

        $montoEsperado = $sesion->monto_inicial + $efectivoVentas;
        $diferencia = $montoFisico - $montoEsperado;

        // Calcular resumen de ventas por método para guardar la "foto" final
        $resumenVentas = DB::table('pagos')
            ->where('caja_sesion_id', $sesionId)
            ->select('metodo_pago', DB::raw('SUM(monto_pagado) as total'))
            ->groupBy('metodo_pago')
            ->get();

        $sesion->update([
            'monto_final_esperado' => $montoEsperado,
            'monto_final_fisico' => $montoFisico,
            'diferencia' => $diferencia,
            'desglose_efectivo' => $desglose,
            'resumen_ventas' => $resumenVentas,
            'estado' => 'cerrada',
            'fecha_cierre' => now(),
            'comentario' => $comentario
        ]);

        return $sesion;
    }

    public function getResumenCierre(int $sesionId)
    {
        $sesion = CajaSesion::findOrFail($sesionId);

        // 1. Ventas por Método de Pago
        $pagos = DB::table('pagos')
            ->where('caja_sesion_id', $sesionId)
            ->select('metodo_pago', DB::raw('SUM(monto_pagado) as total'), DB::raw('COUNT(*) as cantidad'))
            ->groupBy('metodo_pago')
            ->get();

        // 2. Totales Generales (Solo facturas de esta sesión)
        $totales = DB::table('facturas')
            ->where('caja_sesion_id', $sesionId)
            ->selectRaw('COUNT(*) as cantidad_facturas, SUM(total) as total_venta, SUM(itbis) as total_itbis, SUM(descuento_total) as total_descuento')
            ->first();

        // 3. Ventas por Tipo (Contado vs Credito)
        $porTipo = DB::table('facturas')
            ->where('caja_sesion_id', $sesionId)
            ->select('tipo_factura', DB::raw('SUM(total) as total'))
            ->groupBy('tipo_factura')
            ->get();

        $efectivo = $pagos->where('metodo_pago', 'efectivo')->first()->total ?? 0;

        return [
            'monto_inicial' => (double)$sesion->monto_inicial,
            'ventas_por_metodo' => $pagos,
            'ventas_por_tipo' => $porTipo,
            'totales_generales' => [
                'cantidad_facturas' => (int)$totales->cantidad_facturas,
                'total_venta' => (double)$totales->total_venta,
                'total_itbis' => (double)$totales->total_itbis,
                'total_descuento' => (double)$totales->total_descuento,
            ],
            'monto_esperado_efectivo' => (double)$sesion->monto_inicial + (double)$efectivo,
            'fecha_apertura' => $sesion->fecha_apertura,
        ];
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
    /**
     * Obtener el historial de sesiones de caja con filtros
     */
    public function getHistorial(array $filters = [])
    {
        $query = CajaSesion::with(['caja', 'turno', 'usuario'])
            ->orderBy('fecha_apertura', 'desc');

        if (isset($filters['fecha_desde'])) {
            $query->where('fecha_apertura', '>=', $filters['fecha_desde']);
        }

        if (isset($filters['fecha_hasta'])) {
            $query->where('fecha_apertura', '<=', $filters['fecha_hasta'] . ' 23:59:59');
        }

        if (isset($filters['user_id'])) {
            $query->where('user_id', $filters['user_id']);
        }

        if (isset($filters['estado'])) {
            $query->where('estado', $filters['estado']);
        }

        if (isset($filters['caja_id'])) {
            $query->where('caja_id', $filters['caja_id']);
        }

        return $query->paginate($filters['per_page'] ?? 15);
    }
}
