<?php

namespace App\Services;

use App\Models\Producto;
use App\Models\Ingrediente;
use App\Models\MovimientoInventario;
use Illuminate\Support\Facades\DB;
use Exception;

class InventoryService
{
    /**
     * Procesar el descuento de inventario para una venta
     */
    public function procesarVenta(int $productoId, float $cantidadVenta, string $referencia = '')
    {
        $producto = Producto::with('recetas.ingrediente')->findOrFail($productoId);

        if ($producto->tipo_producto === 'PLATO') {
            foreach ($producto->recetas as $receta) {
                $cantidadADescontar = $receta->cantidad * $cantidadVenta;
                $this->descontarIngrediente($receta->ingrediente_id, $cantidadADescontar, "VENTA: $referencia");
            }
        } else {
            // VENTA_DIRECTA
            if ($producto->maneja_inventario) {
                $producto->decrement('stock_actual', $cantidadVenta);
                // Aquí podrías registrar un movimiento de producto si existiera la tabla
            }
        }
    }

    /**
     * Descontar stock de un ingrediente y registrar movimiento
     */
    private function descontarIngrediente(int $ingredienteId, float $cantidad, string $referencia)
    {
        $ingrediente = Ingrediente::findOrFail($ingredienteId);
        
        // Validar stock (opcional, depende de si permites stock negativo)
        // if ($ingrediente->stock < $cantidad) {
        //     throw new Exception("Stock insuficiente para el ingrediente: {$ingrediente->nombre}");
        // }

        $ingrediente->decrement('stock', $cantidad);

        MovimientoInventario::create([
            'ingrediente_id' => $ingredienteId,
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
            $costoTotal += $receta->cantidad * $receta->ingrediente->costo_unitario;
        }

        return $costoTotal;
    }
}
