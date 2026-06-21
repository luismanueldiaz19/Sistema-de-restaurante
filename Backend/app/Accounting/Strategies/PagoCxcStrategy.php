<?php

namespace App\Accounting\Strategies;

use App\Accounting\AsientoStrategy;
use Exception;

class PagoCxcStrategy implements AsientoStrategy
{
    public function generarDetalles(array $configs, float $subtotal, float $itbis, float $total, float $costo = 0.0): array
    {
        $cuentaCxc = $configs['venta_credito_debe'] ?? null; // Cuentas por Cobrar Clientes
        $cuentaCajaBanco = $configs['pago_cxc_efectivo_debe'] ?? null; // Efectivo/Banco entrante

        if (!$cuentaCxc) {
            throw new Exception("Falta configurar la cuenta para Cuentas por Cobrar Clientes (venta_credito_debe).");
        }
        if (!$cuentaCajaBanco) {
            throw new Exception("Falta configurar la cuenta para Efectivo/Banco entrante (pago_cxc_efectivo_debe).");
        }

        $detalles = [];

        // DÉBITO: Caja/Banco (aumenta el dinero)
        $detalles[] = [
            'cuenta_id' => $cuentaCajaBanco,
            'debito' => $total, // $total is the amount received
            'credito' => 0.00
        ];

        // CRÉDITO: Cuentas por Cobrar (disminuye la deuda que nos deben)
        $detalles[] = [
            'cuenta_id' => $cuentaCxc,
            'debito' => 0.00,
            'credito' => $total
        ];

        return $detalles;
    }
}
