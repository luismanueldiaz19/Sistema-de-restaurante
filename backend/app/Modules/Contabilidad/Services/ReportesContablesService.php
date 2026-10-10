<?php

namespace App\Modules\Contabilidad\Services;

use Illuminate\Support\Facades\DB;

class ReportesContablesService
{
    /**
     * Genera el Libro Diario en un rango de fechas.
     */
    public function generarLibroDiario($fechaInicio, $fechaFin)
    {
        return DB::table('asientos_contables as ac')
            ->join('asiento_detalles as ad', 'ac.id', '=', 'ad.asiento_id')
            ->join('catalogo_cuentas as cc', 'ad.cuenta_id', '=', 'cc.id')
            ->select(
                'ac.id as asiento_id',
                'ac.fecha',
                'ac.glosa',
                'ac.referencia',
                'cc.codigo',
                'cc.nombre as cuenta_nombre',
                'ad.debito',
                'ad.credito'
            )
            ->whereBetween('ac.fecha', [$fechaInicio, $fechaFin])
            ->where('ac.estado', 'Posteado')
            ->orderBy('ac.fecha', 'asc')
            ->orderBy('ac.id', 'asc')
            ->get();
    }

    /**
     * Genera el Libro Mayor (Muestra el movimiento por cada cuenta).
     */
    public function generarLibroMayor($fechaInicio, $fechaFin, $cuentaId = null)
    {
        $query = DB::table('asiento_detalles as ad')
            ->join('asientos_contables as ac', 'ad.asiento_id', '=', 'ac.id')
            ->join('catalogo_cuentas as cc', 'ad.cuenta_id', '=', 'cc.id')
            ->select(
                'cc.id as cuenta_id',
                'cc.codigo',
                'cc.nombre',
                'cc.tipo',
                DB::raw('SUM(ad.debito) as total_debito'),
                DB::raw('SUM(ad.credito) as total_credito')
            )
            ->whereBetween('ac.fecha', [$fechaInicio, $fechaFin])
            ->where('ac.estado', 'Posteado')
            ->groupBy('cc.id', 'cc.codigo', 'cc.nombre', 'cc.tipo');

        if ($cuentaId) {
            $query->where('cc.id', $cuentaId);
        }

        return $query->get();
    }

    /**
     * Genera el Balance de Comprobación (Debe = Haber).
     */
    public function generarBalanceComprobacion($fechaInicio, $fechaFin)
    {
        $mayor = $this->generarLibroMayor($fechaInicio, $fechaFin);
        
        $balance = $mayor->map(function ($cuenta) {
            $saldo = 0;
            // Naturaleza de las cuentas:
            // Activos (1) y Gastos/Costos (5,6) aumentan por débito.
            // Pasivos (2), Capital (3) e Ingresos (4) aumentan por crédito.
            
            $tipo = strtoupper(substr($cuenta->codigo, 0, 1));
            
            if (in_array($tipo, ['1', '5', '6'])) { // Deudora
                $saldo = $cuenta->total_debito - $cuenta->total_credito;
            } else { // Acreedora
                $saldo = $cuenta->total_credito - $cuenta->total_debito;
            }

            $cuenta->saldo = $saldo;
            return $cuenta;
        });

        return $balance;
    }
}
