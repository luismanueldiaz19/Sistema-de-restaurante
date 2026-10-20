<?php
declare(strict_types=1);

namespace App\Modules\Contabilidad\Strategies;

use Exception;

class AsientoStrategyFactory
{
    /**
     * Registro estático de estrategias contables soportadas.
     *
     * @var array<string, class-string<AsientoStrategy>>
     */
    private static array $strategies = [
        'venta_efectivo'    => VentaEfectivoStrategy::class,
        'venta_credito'     => VentaCreditoStrategy::class,
        'compra_inventario' => CompraInventarioStrategy::class,
        'pago_nomina'       => PagoNominaStrategy::class,
        'pago_compra'       => PagoCompraStrategy::class,
        'devolucion_compra' => DevolucionCompraStrategy::class,
        'pago_dgii'         => PagoDgiiStrategy::class,
        'devolucion_venta'  => DevolucionVentaStrategy::class,
        'pago_cxc'          => PagoCxcStrategy::class,
        'ajuste_inventario' => AjusteInventarioStrategy::class,
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
