<?php

namespace App\Accounting\Strategies;

use App\Accounting\AsientoStrategy;
use Exception;

class PagoNominaStrategy implements AsientoStrategy
{
    public function generarDetalles(array $configs, float $subtotal, float $itbis, float $total): array
    {
        $cuentaGasto = $configs['nomina_gasto_debe'] ?? null;
        $cuentaPago = $configs['nomina_pago_haber'] ?? null;

        if (!$cuentaGasto) {
            throw new Exception("Falta configurar la cuenta de débito para Gastos de Nómina y Salarios.");
        }
        if (!$cuentaPago) {
            throw new Exception("Falta configurar la cuenta de crédito para Banco de Desembolso de Nómina.");
        }

        $detalles = [];

        // DÉBITO: Gasto Operativo (Nómina) -> Total
        $detalles[] = [
            'cuenta_id' => $cuentaGasto,
            'debito' => $total,
            'credito' => 0.00
        ];

        // CRÉDITO: Banco / Efectivo -> Total
        $detalles[] = [
            'cuenta_id' => $cuentaPago,
            'debito' => 0.00,
            'credito' => $total
        ];

        return $detalles;
    }
}
