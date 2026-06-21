<?php

namespace App\Accounting\Strategies;

use App\Accounting\AsientoStrategy;
use Exception;

class PagoCompraStrategy implements AsientoStrategy
{
    public function generarDetalles(array $configs, float $subtotal, float $itbis, float $total, float $costo = 0.0): array
    {
        $cuentaProveedor = $configs['compra_proveedor_haber'] ?? null;
        $cuentaCajaBanco = $configs['pago_compra_efectivo_haber'] ?? null;

        if (!$cuentaProveedor) {
            throw new Exception("Falta configurar la cuenta para Cuentas por Pagar Proveedores.");
        }
        if (!$cuentaCajaBanco) {
            throw new Exception("Falta configurar la cuenta para Efectivo/Banco (pago_compra_efectivo_haber).");
        }

        $detalles = [];

        // DÉBITO: Cuentas por Pagar (disminuye la deuda)
        $detalles[] = [
            'cuenta_id' => $cuentaProveedor,
            'debito' => $total, // $total is the amount paid
            'credito' => 0.00
        ];

        // CRÉDITO: Caja/Banco (disminuye el dinero)
        $detalles[] = [
            'cuenta_id' => $cuentaCajaBanco,
            'debito' => 0.00,
            'credito' => $total
        ];

        return $detalles;
    }
}
