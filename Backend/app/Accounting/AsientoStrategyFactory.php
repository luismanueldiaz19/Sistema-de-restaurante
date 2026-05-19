<?php

namespace App\Accounting;

use App\Accounting\Strategies\VentaEfectivoStrategy;
use App\Accounting\Strategies\VentaCreditoStrategy;
use App\Accounting\Strategies\CompraInventarioStrategy;
use App\Accounting\Strategies\PagoNominaStrategy;
use Exception;

class AsientoStrategyFactory
{
    /**
     * Registro estático de estrategias contables soportadas.
     *
     * @var array
     */
    private static $strategies = [
        'venta_efectivo' => VentaEfectivoStrategy::class,
        'venta_credito' => VentaCreditoStrategy::class,
        'compra_inventario' => CompraInventarioStrategy::class,
        'pago_nomina' => PagoNominaStrategy::class,
    ];

    /**
     * Obtener una instancia de la estrategia correspondiente al tipo de transacción.
     *
     * @param  string  $tipoTransaccion
     * @return AsientoStrategy
     * @throws Exception
     */
    public static function make(string $tipoTransaccion): AsientoStrategy
    {
        if (!isset(self::$strategies[$tipoTransaccion])) {
            throw new Exception("Tipo de transacción contable no soportado: '{$tipoTransaccion}'");
        }

        $class = self::$strategies[$tipoTransaccion];
        return new $class();
    }
}
