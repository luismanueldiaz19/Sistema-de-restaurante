<?php
declare(strict_types=1);

namespace App\Modules\Contabilidad\Strategies;

interface AsientoStrategy
{
    /**
     * Generar las líneas de débito y crédito del asiento contable.
     *
     * @param  array  $configs  Configuraciones contables actuales (clave => cuenta_id).
     * @param  float  $subtotal
     * @param  float  $itbis
     * @param  float  $total
     * @param  float  $costo
     * @return array  Listado de arrays asociativos con ['cuenta_id', 'debito', 'credito'].
     * @throws \Exception
     */
    public function generarDetalles(array $configs, float $subtotal, float $itbis, float $total, float $costo = 0.0): array;
}
