<?php
declare(strict_types=1);

namespace App\Modules\Contabilidad\Strategies;

use Exception;

class VentaEfectivoStrategy implements AsientoStrategy
{
    public function generarDetalles(array $configs, float $subtotal, float $itbis, float $total, float $costo = 0.0): array
    {
        $cuentaCobro = $configs['venta_efectivo_debe'] ?? null;
        $cuentaVenta = $configs['venta_haber'] ?? null;
        $cuentaItbis = $configs['venta_itbis_haber'] ?? null;

        if (!$cuentaCobro) {
            throw new Exception("Falta configurar la cuenta de débito para Cobro en Efectivo (Ventas al Contado).");
        }
        if (!$cuentaVenta) {
            throw new Exception("Falta configurar la cuenta de crédito para Ventas de Alimentos.");
        }

        $detalles = [];

        // DÉBITO: Caja General / Efectivo -> Total
        $detalles[] = [
            'cuenta_id' => $cuentaCobro,
            'debito' => $total,
            'credito' => 0.00
        ];

        // CRÉDITO: Ventas -> Subtotal (con soporte para desglose de cuentas por producto)
        $detallesArray = $configs['detalles'] ?? [];
        if (!empty($detallesArray)) {
            $subtotalesPorCuenta = [];
            foreach ($detallesArray as $d) {
                $cuentaId = $d['cuenta_ingreso_id'] ?? $cuentaVenta;
                if (!$cuentaId) {
                    $cuentaId = $cuentaVenta;
                }
                $montoLinea = floatval($d['subtotal'] ?? 0.0);
                if (!isset($subtotalesPorCuenta[$cuentaId])) {
                    $subtotalesPorCuenta[$cuentaId] = 0.0;
                }
                $subtotalesPorCuenta[$cuentaId] += $montoLinea;
            }

            // Validar que la suma de subtotales cuadre exactamente con $subtotal
            $sumaDetalles = array_sum($subtotalesPorCuenta);
            $dif = round($subtotal - $sumaDetalles, 2);
            if (abs($dif) > 0 && abs($dif) <= 0.05 && count($subtotalesPorCuenta) > 0) {
                $primeraCuenta = array_key_first($subtotalesPorCuenta);
                $subtotalesPorCuenta[$primeraCuenta] = round($subtotalesPorCuenta[$primeraCuenta] + $dif, 2);
            }

            foreach ($subtotalesPorCuenta as $cId => $monto) {
                if ($monto > 0) {
                    $detalles[] = [
                        'cuenta_id' => $cId,
                        'debito' => 0.00,
                        'credito' => round($monto, 2)
                    ];
                }
            }
        } else {
            $detalles[] = [
                'cuenta_id' => $cuentaVenta,
                'debito' => 0.00,
                'credito' => $subtotal
            ];
        }

        // CRÉDITO: ITBIS por Pagar -> ITBIS
        if ($itbis > 0) {
            if (!$cuentaItbis) {
                throw new Exception("Falta configurar la cuenta de crédito para ITBIS por Pagar (Ventas).");
            }
            $detalles[] = [
                'cuenta_id' => $cuentaItbis,
                'debito' => 0.00,
                'credito' => $itbis
            ];
        }

        // DÉBITO: Costo de Ventas -> Costo
        // CRÉDITO: Inventario -> Costo
        if ($costo > 0) {
            $cuentaCosto = $configs['venta_costo_debe'] ?? null;
            $cuentaInventario = $configs['venta_inventario_haber'] ?? null;
            
            if ($cuentaCosto && $cuentaInventario) {
                $detalles[] = [
                    'cuenta_id' => $cuentaCosto,
                    'debito' => $costo,
                    'credito' => 0.00
                ];
                $detalles[] = [
                    'cuenta_id' => $cuentaInventario,
                    'debito' => 0.00,
                    'credito' => $costo
                ];
            }
        }

        return $detalles;
    }
}
