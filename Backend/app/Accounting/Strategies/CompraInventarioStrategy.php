<?php

namespace App\Accounting\Strategies;

use App\Accounting\AsientoStrategy;
use Exception;

class CompraInventarioStrategy implements AsientoStrategy
{
    public function generarDetalles(array $configs, float $subtotal, float $itbis, float $total, float $costo = 0.0): array
    {
        $cuentaInventario = $configs['compra_inventario_debe'] ?? null;
        $cuentaProveedor = $configs['compra_proveedor_haber'] ?? null;
        $cuentaItbis = $configs['compra_itbis_debe'] ?? null;
        $cuentaItbisRetenido = $configs['itbis_retenido_por_pagar'] ?? null;
        $esInformal = isset($configs['es_informal']) && $configs['es_informal'] === true;

        if (!$cuentaInventario) {
            throw new Exception("Falta configurar la cuenta de débito para Inventario de Alimentos.");
        }
        if (!$cuentaProveedor) {
            throw new Exception("Falta configurar la cuenta de crédito para Cuentas por Pagar Proveedores.");
        }

        $detalles = [];

        $detallesArray = $configs['detalles'] ?? [];

        // Agrupar subtotal por cuenta contable (Gastos vs Inventario)
        if (!empty($detallesArray)) {
            $subtotalesPorCuenta = [];
            foreach ($detallesArray as $d) {
                $cuentaId = $d['cuenta_contable_id'] ?? $cuentaInventario;
                if (!$cuentaId) {
                    $cuentaId = $cuentaInventario; // Fallback
                }
                $subtotalLinea = floatval($d['subtotal'] ?? ($d['cantidad'] * $d['costo_unitario']));
                
                if (!isset($subtotalesPorCuenta[$cuentaId])) {
                    $subtotalesPorCuenta[$cuentaId] = 0.0;
                }
                $subtotalesPorCuenta[$cuentaId] += $subtotalLinea;
            }

            foreach ($subtotalesPorCuenta as $cId => $monto) {
                if ($monto > 0) {
                    $detalles[] = [
                        'cuenta_id' => $cId,
                        'debito' => $monto,
                        'credito' => 0.00
                    ];
                }
            }
        } else {
            // DÉBITO: Inventario -> Subtotal (Fallback original)
            $detalles[] = [
                'cuenta_id' => $cuentaInventario,
                'debito' => $subtotal,
                'credito' => 0.00
            ];
        }

        // DÉBITO: ITBIS adelantado en Compras -> ITBIS
        if ($itbis > 0) {
            if (!$cuentaItbis) {
                throw new Exception("Falta configurar la cuenta de débito para ITBIS en Compras.");
            }
            $detalles[] = [
                'cuenta_id' => $cuentaItbis,
                'debito' => $itbis,
                'credito' => 0.00
            ];
        }

        // Si es informal y hay ITBIS, se retiene el 100%
        if ($esInformal && $itbis > 0) {
            if (!$cuentaItbisRetenido) {
                throw new Exception("Falta configurar la cuenta de crédito para ITBIS Retenido por Pagar.");
            }
            // CRÉDITO: ITBIS Retenido por Pagar -> ITBIS
            $detalles[] = [
                'cuenta_id' => $cuentaItbisRetenido,
                'debito' => 0.00,
                'credito' => $itbis
            ];
            
            // CRÉDITO: Cuentas por Pagar Proveedor -> Solo Subtotal (porque le retenemos el ITBIS)
            $detalles[] = [
                'cuenta_id' => $cuentaProveedor,
                'debito' => 0.00,
                'credito' => $subtotal
            ];
        } else {
            // CRÉDITO: Cuentas por Pagar Proveedor -> Total Normal
            $detalles[] = [
                'cuenta_id' => $cuentaProveedor,
                'debito' => 0.00,
                'credito' => $total
            ];
        }

        return $detalles;
    }
}
