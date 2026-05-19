<?php

namespace App\Accounting\Strategies;

use App\Accounting\AsientoStrategy;
use Exception;

class VentaEfectivoStrategy implements AsientoStrategy
{
    public function generarDetalles(array $configs, float $subtotal, float $itbis, float $total): array
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

        return $detalles;
    }
}
