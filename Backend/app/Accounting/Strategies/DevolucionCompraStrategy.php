<?php

namespace App\Accounting\Strategies;

use App\Accounting\AsientoStrategy;
use Exception;

class DevolucionCompraStrategy implements AsientoStrategy
{
    public function generarDetalles(array $configs, float $subtotal, float $itbis, float $total, float $costo = 0.0): array
    {
        $cuentaInventario = $configs['compra_inventario_debe'] ?? null;
        $cuentaProveedor = $configs['compra_proveedor_haber'] ?? null;
        $cuentaItbis = $configs['compra_itbis_debe'] ?? null;

        if (!$cuentaInventario) {
            throw new Exception("Falta configurar la cuenta para Inventario de Alimentos.");
        }
        if (!$cuentaProveedor) {
            throw new Exception("Falta configurar la cuenta para Cuentas por Pagar Proveedores.");
        }

        $detalles = [];

        // DÉBITO: Cuentas por Pagar Proveedor -> Total (disminuye deuda)
        $detalles[] = [
            'cuenta_id' => $cuentaProveedor,
            'debito' => $total,
            'credito' => 0.00
        ];

        // CRÉDITO: Inventario -> Subtotal (disminuye inventario)
        $detalles[] = [
            'cuenta_id' => $cuentaInventario,
            'debito' => 0.00,
            'credito' => $subtotal
        ];

        // CRÉDITO: ITBIS adelantado -> ITBIS (revierte el itbis de la compra original)
        if ($itbis > 0) {
            if (!$cuentaItbis) {
                throw new Exception("Falta configurar la cuenta de ITBIS en Compras.");
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
