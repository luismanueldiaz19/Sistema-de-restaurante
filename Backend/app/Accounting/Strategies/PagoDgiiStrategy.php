<?php

namespace App\Accounting\Strategies;

use App\Accounting\AsientoStrategy;
use Exception;

class PagoDgiiStrategy implements AsientoStrategy
{
    public function generarDetalles(array $configs, float $subtotal, float $itbis, float $total): array
    {
        // En este caso, $total representa el monto pagado a la DGII.
        // El ITBIS POR PAGAR (2.1.02) se debita (disminuye pasivo).
        // La cuenta de Banco se acredita (disminuye activo).
        // Como la cuenta origen (Banco) viene en la solicitud y no está fija en config,
        // esperaremos que el DgiiController la inyecte temporalmente en $configs.
        
        $cuentaItbis = $configs['pago_dgii_itbis_debe'] ?? null;
        $cuentaBanco = $configs['pago_dgii_banco_haber'] ?? null;

        if (!$cuentaItbis) {
            throw new Exception("Falta configurar la cuenta de débito para el Pago a DGII (ITBIS POR PAGAR).");
        }
        if (!$cuentaBanco) {
            throw new Exception("Falta la cuenta bancaria de origen para registrar el pago a la DGII.");
        }

        $detalles = [];

        // DÉBITO: ITBIS POR PAGAR -> Para saldar o reducir la deuda
        $detalles[] = [
            'cuenta_id' => $cuentaItbis,
            'debito' => $total,
            'credito' => 0.00
        ];

        // CRÉDITO: BANCO -> Sale el dinero
        $detalles[] = [
            'cuenta_id' => $cuentaBanco,
            'debito' => 0.00,
            'credito' => $total
        ];

        return $detalles;
    }
}
