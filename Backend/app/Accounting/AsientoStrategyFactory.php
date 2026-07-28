<?php

namespace App\Accounting;

use App\Accounting\Strategies\VentaEfectivoStrategy;
use App\Accounting\Strategies\VentaCreditoStrategy;
use App\Accounting\Strategies\CompraInventarioStrategy;
use App\Accounting\Strategies\PagoNominaStrategy;
use App\Accounting\Strategies\PagoCompraStrategy;
use App\Accounting\Strategies\DevolucionCompraStrategy;
use App\Accounting\Strategies\PagoDgiiStrategy;
use App\Accounting\Strategies\DevolucionVentaStrategy;
use App\Accounting\Strategies\PagoCxcStrategy;
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
        'pago_compra' => PagoCompraStrategy::class,
        'devolucion_compra' => DevolucionCompraStrategy::class,
        'pago_dgii' => PagoDgiiStrategy::class,
        'devolucion_venta' => DevolucionVentaStrategy::class,
        'pago_cxc' => PagoCxcStrategy::class,
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
