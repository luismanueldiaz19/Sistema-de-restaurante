<?php

namespace App\Accounting\Strategies;

use App\Accounting\AsientoStrategy;
use Exception;

class DevolucionVentaStrategy implements AsientoStrategy
{
    public function generarDetalles(array $configs, float $subtotal, float $itbis, float $total, float $costo = 0.0): array
    {
        $cuentaCobro = $configs['venta_efectivo_debe'] ?? null;
        $cuentaVenta = $configs['venta_haber'] ?? null;
        $cuentaItbis = $configs['venta_itbis_haber'] ?? null;

        if (!$cuentaCobro) {
            throw new Exception("Falta configurar la cuenta de Efectivo/Caja para procesar devoluciones.");
        }
        if (!$cuentaVenta) {
            throw new Exception("Falta configurar la cuenta de Ventas para revertir.");
        }

        $detalles = [];

        // CRÉDITO: Caja General / Efectivo -> Total (El dinero sale)
        $detalles[] = [
            'cuenta_id' => $cuentaCobro,
            'debito' => 0.00,
            'credito' => $total
        ];

        // DÉBITO: Ventas -> Subtotal (Revertir venta)
        $detalles[] = [
            'cuenta_id' => $cuentaVenta,
            'debito' => $subtotal,
            'credito' => 0.00
        ];

        // DÉBITO: ITBIS por Pagar -> ITBIS (Revertir pasivo)
        if ($itbis > 0) {
            if (!$cuentaItbis) {
                throw new Exception("Falta configurar la cuenta de ITBIS por Pagar (Ventas).");
            }
            $detalles[] = [
                'cuenta_id' => $cuentaItbis,
                'debito' => $itbis,
                'credito' => 0.00
            ];
        }

        // Revertir el Costo de Ventas
        // DÉBITO: Inventario -> Costo
        // CRÉDITO: Costo de Ventas -> Costo
        if ($costo > 0) {
            $cuentaCosto = $configs['venta_costo_debe'] ?? null;
            $cuentaInventario = $configs['venta_inventario_haber'] ?? null;
            
            if ($cuentaCosto && $cuentaInventario) {
                $detalles[] = [
                    'cuenta_id' => $cuentaInventario,
                    'debito' => $costo,
                    'credito' => 0.00
                ];
                $detalles[] = [
                    'cuenta_id' => $cuentaCosto,
                    'debito' => 0.00,
                    'credito' => $costo
                ];
            }
        }

        return $detalles;
    }
}
