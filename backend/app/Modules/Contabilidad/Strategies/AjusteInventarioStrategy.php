<?php

declare(strict_types=1);

namespace App\Modules\Contabilidad\Strategies;

use Exception;

class AjusteInventarioStrategy implements AsientoStrategy
{
    /**
     * Generar líneas de partida doble para Ajustes de Inventario (Mermas o Sobrantes)
     */
    public function generarDetalles(array $configs, float $subtotal, float $itbis, float $total, float $costo = 0.0): array
    {
        $tipoAjuste = strtoupper((string) ($configs['tipo_ajuste'] ?? 'SALIDA'));
        $cuentaInventario = $configs['venta_inventario_haber'] ?? $configs['compra_inventario_debe'] ?? null;
        $cuentaPerdida = $configs['venta_costo_debe'] ?? null;
        $cuentaGanancia = $configs['venta_haber'] ?? null;

        if (!$cuentaInventario) {
            throw new Exception("Falta configurar la cuenta de Inventario para registrar asientos de ajuste.");
        }

        $detalles = [];

        if ($tipoAjuste === 'SALIDA') {
            // SALIDA (Merma, daño, vencimiento o pérdida física):
            // DÉBITO: Costo de Ventas / Pérdida por Ajuste (Gasto/Costo)
            // CRÉDITO: Inventario de Alimentos y Bebidas (Baja del activo)
            if (!$cuentaPerdida) {
                throw new Exception("Falta configurar la cuenta de Costo/Gasto para el ajuste de salida.");
            }

            $detalles[] = [
                'cuenta_id' => $cuentaPerdida,
                'debito'    => $total,
                'credito'   => 0.00,
            ];

            $detalles[] = [
                'cuenta_id' => $cuentaInventario,
                'debito'    => 0.00,
                'credito'   => $total,
            ];
        } else {
            // ENTRADA (Sobrante por conteo físico o corrección positiva):
            // DÉBITO: Inventario de Alimentos y Bebidas (Aumento del activo)
            // CRÉDITO: Ingreso por Ajuste de Inventario (Ganancia)
            if (!$cuentaGanancia) {
                throw new Exception("Falta configurar la cuenta de Ingresos para el ajuste de entrada.");
            }

            $detalles[] = [
                'cuenta_id' => $cuentaInventario,
                'debito'    => $total,
                'credito'   => 0.00,
            ];

            $detalles[] = [
                'cuenta_id' => $cuentaGanancia,
                'debito'    => 0.00,
                'credito'   => $total,
            ];
        }

        return $detalles;
    }
}
