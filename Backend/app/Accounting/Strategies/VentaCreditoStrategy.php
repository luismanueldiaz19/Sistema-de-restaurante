<?php

namespace App\Accounting\Strategies;

use App\Accounting\AsientoStrategy;
use Exception;

class VentaCreditoStrategy implements AsientoStrategy
{
    public function generarDetalles(array $configs, float $subtotal, float $itbis, float $total, float $costo = 0.0): array
    {
        $cuentaCobro = $configs['venta_credito_debe'] ?? null;
        $cuentaVenta = $configs['venta_haber'] ?? null;
        $cuentaItbis = $configs['venta_itbis_haber'] ?? null;

        if (!$cuentaCobro) {
            throw new Exception("Falta configurar la cuenta de débito para Cobro a Crédito (Cuentas por Cobrar Clientes).");
        }
        if (!$cuentaVenta) {
            throw new Exception("Falta configurar la cuenta de crédito para Ventas de Alimentos.");
        }

        $detalles = [];

        // DÉBITO: Cuentas por Cobrar Clientes -> Total
        $detalles[] = [
            'cuenta_id' => $cuentaCobro,
            'debito' => $total,
            'credito' => 0.00
        ];

        // CRÉDITO: Ventas -> Subtotal
        $detalles[] = [
            'cuenta_id' => $cuentaVenta,
            'debito' => 0.00,
            'credito' => $subtotal
        ];

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
