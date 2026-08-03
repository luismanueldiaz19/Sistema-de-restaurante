<?php

namespace App\Services;

use App\Models\Producto;
use App\Models\MovimientoInventario;
use Illuminate\Support\Facades\DB;
use Exception;

class InventoryService
{
    /**
     * Procesar el descuento de inventario para una venta
     */
    public function procesarVenta(int $productoId, float $cantidadVenta, string $referencia = '') {
        $producto = Producto::with('recetas.ingrediente')->findOrFail($productoId);

        if ($producto->tipo_producto === 'PLATO' || $producto->tipo_producto === 'COMBO') {
            foreach ($producto->recetas as $receta) {
                $cantidadADescontar = $receta->cantidad * $cantidadVenta;
                $this->descontarProductoMateriaPrima($receta->ingrediente_producto_id, $cantidadADescontar, "VENTA: $referencia");
            }
        } else {
            // VENTA_DIRECTA
            if ($producto->maneja_inventario) {
                $producto->decrement('stock_actual', $cantidadVenta);
                MovimientoInventario::create([
                    'producto_id' => $productoId,
                    'tipo' => 'SALIDA',
                    'cantidad' => $cantidadVenta,
                    'referencia' => "VENTA: $referencia",
                    'fecha' => now()
                ]);
            }
        }
    }

    /**
     * Descontar stock de un ingrediente (materia prima) y registrar movimiento
     */
    private function descontarProductoMateriaPrima(int $productoId, float $cantidad, string $referencia) {

        $producto = Producto::findOrFail($productoId);

        $producto->decrement('stock_actual', $cantidad);
        
        MovimientoInventario::create([
            'producto_id' => $productoId,
            'tipo' => 'SALIDA',
            'cantidad' => $cantidad,
            'referencia' => $referencia,
            'fecha' => now()
        ]);
    }

    /**
     * Calcular costo de un producto basado en su receta
     */                                                 
    public function calcularCostoProducto(int $productoId)
    {
        $producto = Producto::with('recetas.ingrediente')->findOrFail($productoId);
        
        if ($producto->tipo_producto !== 'PLATO') {
            return $producto->costo;
        }

        $costoTotal = 0;

        foreach ($producto->recetas as $receta) {
            $costoTotal += $receta->cantidad * ($receta->ingrediente->costo ?? 0);
        }

        return $costoTotal;
    }
}
