<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\CatalogoCuenta;
use App\Models\AsientoDetalle;
use Illuminate\Support\Facades\DB;

class ReporteContableController extends Controller
{
    /**
     * Reporte de Mayor General.
     * Retorna todas las cuentas de detalle con sus débitos, créditos y saldo en un rango de fechas.
     */
    public function mayorGeneral(Request $request)
    {
        $fechaDesde = $request->input('fecha_desde', '2000-01-01');
        $fechaHasta = $request->input('fecha_hasta', now()->toDateString());

        // Obtener cuentas de detalle (permite_movimiento = true)
        $cuentas = CatalogoCuenta::where('permite_movimiento', true)->orderBy('codigo')->get();

        // Obtener la suma de débitos y créditos por cuenta en el rango de fechas
        $saldos = DB::table('asiento_detalles')
            ->join('asientos_contables', 'asiento_detalles.asiento_id', '=', 'asientos_contables.id')
            ->select(
                'cuenta_id',
                DB::raw('SUM(debito) as total_debito'),
                DB::raw('SUM(credito) as total_credito')
            )
            ->where('asientos_contables.estado', 'Posteado')
            ->whereBetween('asientos_contables.fecha', [$fechaDesde, $fechaHasta])
            ->groupBy('cuenta_id')
            ->get()
            ->keyBy('cuenta_id');

        $resultado = $cuentas->map(function ($cuenta) use ($saldos) {
            $saldo = $saldos->get($cuenta->id);
            $debito = $saldo ? (float) $saldo->total_debito : 0;
            $credito = $saldo ? (float) $saldo->total_credito : 0;

            // Determinar naturaleza de la cuenta para calcular el balance final
            $naturalezaDeudora = in_array($cuenta->tipo, ['Activo', 'Costos', 'Gastos']);
            $balance = $naturalezaDeudora ? ($debito - $credito) : ($credito - $debito);

            return [
                'id' => $cuenta->id,
                'codigo' => $cuenta->codigo,
                'nombre' => $cuenta->nombre,
                'tipo' => $cuenta->tipo,
                'total_debito' => $debito,
                'total_credito' => $credito,
                'balance' => $balance
            ];
        })->filter(function ($c) {
            // Filtrar cuentas que no tienen movimientos
            return $c['total_debito'] > 0 || $c['total_credito'] > 0 || $c['balance'] != 0;
        })->values();

        return response()->json(['data' => $resultado]);
    }

    /**
     * Balance General (Activo, Pasivo, Capital)
     */
    public function balanceGeneral(Request $request)
    {
        $fechaHasta = $request->input('fecha_hasta', now()->toDateString());

        $cuentas = CatalogoCuenta::all();
        $saldos = DB::table('asiento_detalles')
            ->join('asientos_contables', 'asiento_detalles.asiento_id', '=', 'asientos_contables.id')
            ->select('cuenta_id', DB::raw('SUM(debito) as debito'), DB::raw('SUM(credito) as credito'))
            ->where('asientos_contables.estado', 'Posteado')
            ->where('asientos_contables.fecha', '<=', $fechaHasta)
            ->groupBy('cuenta_id')
            ->get()
            ->keyBy('cuenta_id');

        // Función recursiva para calcular balance de cuentas agrupadoras
        $calcularBalance = function ($cuenta) use (&$calcularBalance, $cuentas, $saldos) {
            if ($cuenta->permite_movimiento) {
                $saldo = $saldos->get($cuenta->id);
                $d = $saldo ? (float) $saldo->debito : 0;
                $c = $saldo ? (float) $saldo->credito : 0;
                $naturalezaDeudora = in_array($cuenta->tipo, ['Activo', 'Costos', 'Gastos']);
                $bal = $naturalezaDeudora ? ($d - $c) : ($c - $d);
                return [
                    'codigo' => $cuenta->codigo,
                    'nombre' => $cuenta->nombre,
                    'tipo' => $cuenta->tipo,
                    'balance' => $bal,
                    'es_detalle' => true,
                    'hijos' => []
                ];
            } else {
                // Incluir cualquier saldo registrado directamente a la cuenta padre (evita descuadres visuales)
                $saldoPadre = $saldos->get($cuenta->id);
                $dP = $saldoPadre ? (float) $saldoPadre->debito : 0;
                $cP = $saldoPadre ? (float) $saldoPadre->credito : 0;
                $naturalezaDeudoraPadre = in_array($cuenta->tipo, ['Activo', 'Costos', 'Gastos']);
                $sumaBalance = $naturalezaDeudoraPadre ? ($dP - $cP) : ($cP - $dP);

                $hijosDB = $cuentas->where('padre_id', $cuenta->id)->sortBy('codigo');
                $hijos = [];
                foreach ($hijosDB as $hijo) {
                    $resHijo = $calcularBalance($hijo);
                    if ($resHijo['balance'] != 0 || count($resHijo['hijos']) > 0) {
                        $hijos[] = $resHijo;
                        $sumaBalance += $resHijo['balance'];
                    }
                }
                return [
                    'codigo' => $cuenta->codigo,
                    'nombre' => $cuenta->nombre,
                    'tipo' => $cuenta->tipo,
                    'balance' => $sumaBalance,
                    'es_detalle' => false,
                    'hijos' => $hijos
                ];
            }
        };

        $activos = [];
        $pasivos = [];
        $capital = [];

        foreach ($cuentas->where('padre_id', null)->sortBy('codigo') as $raiz) {
            $nodo = $calcularBalance($raiz);
            if ($nodo['balance'] != 0 || count($nodo['hijos']) > 0) {
                if ($raiz->tipo == 'Activo') $activos[] = $nodo;
                if ($raiz->tipo == 'Pasivo') $pasivos[] = $nodo;
                if ($raiz->tipo == 'Capital') $capital[] = $nodo;
            }
        }

        // Utilidad del ejercicio (Ingresos - Costos - Gastos)
        $utilidad = $this->calcularUtilidad($fechaHasta);

        $totalActivo = collect($activos)->sum('balance');
        $totalPasivo = collect($pasivos)->sum('balance');
        $totalCapitalBase = collect($capital)->sum('balance');
        $totalCapital = $totalCapitalBase + $utilidad;

        return response()->json([
            'data' => [
                'activos' => $activos,
                'pasivos' => $pasivos,
                'capital' => $capital,
                'utilidad_ejercicio' => $utilidad,
                'totales' => [
                    'activo' => $totalActivo,
                    'pasivo' => $totalPasivo,
                    'capital' => $totalCapitalBase,
                    'pasivo_y_capital' => $totalPasivo + $totalCapital
                ]
            ]
        ]);
    }

    /**
     * Estado de Resultados (Ingresos, Costos, Gastos)
     */
    public function estadoResultados(Request $request)
    {
        $fechaDesde = $request->input('fecha_desde', '2000-01-01');
        $fechaHasta = $request->input('fecha_hasta', now()->toDateString());

        $cuentas = CatalogoCuenta::all();
        $saldos = DB::table('asiento_detalles')
            ->join('asientos_contables', 'asiento_detalles.asiento_id', '=', 'asientos_contables.id')
            ->select('cuenta_id', DB::raw('SUM(debito) as debito'), DB::raw('SUM(credito) as credito'))
            ->where('asientos_contables.estado', 'Posteado')
            ->whereBetween('asientos_contables.fecha', [$fechaDesde, $fechaHasta])
            ->groupBy('cuenta_id')
            ->get()
            ->keyBy('cuenta_id');

        $calcularBalance = function ($cuenta) use (&$calcularBalance, $cuentas, $saldos) {
            if ($cuenta->permite_movimiento) {
                $saldo = $saldos->get($cuenta->id);
                $d = $saldo ? (float) $saldo->debito : 0;
                $c = $saldo ? (float) $saldo->credito : 0;
                $naturalezaDeudora = in_array($cuenta->tipo, ['Activo', 'Costos', 'Gastos']);
                $bal = $naturalezaDeudora ? ($d - $c) : ($c - $d);
                return [
                    'codigo' => $cuenta->codigo,
                    'nombre' => $cuenta->nombre,
                    'tipo' => $cuenta->tipo,
                    'balance' => $bal,
                    'es_detalle' => true,
                    'hijos' => []
                ];
            } else {
                $hijosDB = $cuentas->where('padre_id', $cuenta->id)->sortBy('codigo');
                $hijos = [];
                $sumaBalance = 0;
                foreach ($hijosDB as $hijo) {
                    $resHijo = $calcularBalance($hijo);
                    if ($resHijo['balance'] != 0 || count($resHijo['hijos']) > 0) {
                        $hijos[] = $resHijo;
                        $sumaBalance += $resHijo['balance'];
                    }
                }
                return [
                    'codigo' => $cuenta->codigo,
                    'nombre' => $cuenta->nombre,
                    'tipo' => $cuenta->tipo,
                    'balance' => $sumaBalance,
                    'es_detalle' => false,
                    'hijos' => $hijos
                ];
            }
        };

        $ingresos = [];
        $costos = [];
        $gastos = [];

        foreach ($cuentas->where('padre_id', null)->sortBy('codigo') as $raiz) {
            $nodo = $calcularBalance($raiz);
            if ($nodo['balance'] != 0 || count($nodo['hijos']) > 0) {
                if ($raiz->tipo == 'Ingresos') $ingresos[] = $nodo;
                if ($raiz->tipo == 'Costos') $costos[] = $nodo;
                if ($raiz->tipo == 'Gastos') $gastos[] = $nodo;
            }
        }

        $totalIngresos = collect($ingresos)->sum('balance');
        $totalCostos = collect($costos)->sum('balance');
        $utilidadBruta = $totalIngresos - $totalCostos;
        $totalGastos = collect($gastos)->sum('balance');
        $utilidadNeta = $utilidadBruta - $totalGastos;

        return response()->json([
            'data' => [
                'ingresos' => $ingresos,
                'costos' => $costos,
                'gastos' => $gastos,
                'totales' => [
                    'ingresos' => $totalIngresos,
                    'costos' => $totalCostos,
                    'utilidad_bruta' => $utilidadBruta,
                    'gastos' => $totalGastos,
                    'utilidad_neta' => $utilidadNeta
                ]
            ]
        ]);
    }

    private function calcularUtilidad($fechaHasta)
    {
        $ingresos = 0;
        $egresos = 0;

        $saldos = DB::table('asiento_detalles')
            ->join('asientos_contables', 'asiento_detalles.asiento_id', '=', 'asientos_contables.id')
            ->join('catalogo_cuentas', 'asiento_detalles.cuenta_id', '=', 'catalogo_cuentas.id')
            ->select('catalogo_cuentas.tipo', DB::raw('SUM(debito) as debito'), DB::raw('SUM(credito) as credito'))
            ->where('asientos_contables.estado', 'Posteado')
            ->where('asientos_contables.fecha', '<=', $fechaHasta)
            ->whereIn('catalogo_cuentas.tipo', ['Ingresos', 'Costos', 'Gastos'])
            ->groupBy('catalogo_cuentas.tipo')
            ->get();

        foreach ($saldos as $s) {
            $d = (float) $s->debito;
            $c = (float) $s->credito;
            if ($s->tipo == 'Ingresos') {
                $ingresos += ($c - $d);
            } else {
                $egresos += ($d - $c);
            }
        }

        return $ingresos - $egresos;
    }
}
