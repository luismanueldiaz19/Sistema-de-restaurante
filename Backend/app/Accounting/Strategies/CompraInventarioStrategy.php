<?php

namespace App\Accounting\Strategies;

use App\Accounting\AsientoStrategy;
use Exception;

class CompraInventarioStrategy implements AsientoStrategy
{
    public function generarDetalles(array $configs, float $subtotal, float $itbis, float $total): array
    {
        $cuentaInventario = $configs['compra_inventario_debe'] ?? null;
        $cuentaProveedor = $configs['compra_proveedor_haber'] ?? null;
        $cuentaItbis = $configs['compra_itbis_debe'] ?? null;

        if (!$cuentaInventario) {
            throw new Exception("Falta configurar la cuenta de débito para Inventario de Alimentos.");
        }
        if (!$cuentaProveedor) {
            throw new Exception("Falta configurar la cuenta de crédito para Cuentas por Pagar Proveedores.");
        }

        $detalles = [];

        // DÉBITO: Inventario -> Subtotal
        $detalles[] = [
            'cuenta_id' => $cuentaInventario,
            'debito' => $subtotal,
            'credito' => 0.00
        ];

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

        // CRÉDITO: Cuentas por Pagar Proveedor -> Total
        $detalles[] = [
            'cuenta_id' => $cuentaProveedor,
            'debito' => 0.00,
            'credito' => $total
        ];

        return $detalles;
    }
}
