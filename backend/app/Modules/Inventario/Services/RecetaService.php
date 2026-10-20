<?php

declare(strict_types=1);

namespace App\Modules\Inventario\Services;

use App\Models\Producto;
use App\Models\Receta;
use App\Modules\Inventario\DTOs\GuardarRecetaDTO;
use App\Modules\Inventario\Exceptions\InventarioException;
use Illuminate\Database\Eloquent\Collection;
use Illuminate\Support\Facades\DB;

class RecetaService
{
    /**
     * Obtener listado de productos que admiten recetas (PLATO, COMBO, PRODUCTO)
     */
    public function getProductosConRecetas(): Collection
    {
        return Producto::with(['recetas.ingrediente.unidadMedida', 'categoria', 'unidadMedida'])
            ->whereIn('tipo_producto', ['PLATO', 'COMBO', 'PRODUCTO'])
            ->where('activo', true)
            ->get();
    }

    /**
     * Obtener la receta detallada de un producto específico
     */
    public function getReceta(int $productoId): Producto
    {
        return Producto::with(['recetas.ingrediente.unidadMedida', 'categoria', 'unidadMedida'])
            ->findOrFail($productoId);
    }

    /**
     * Guardar o actualizar la receta de un producto
     */
    public function guardarReceta(GuardarRecetaDTO $dto): Producto
    {
        $producto = Producto::findOrFail($dto->productoId);

        if (!in_array($producto->tipo_producto, ['PLATO', 'COMBO', 'PRODUCTO'], true)) {
            throw new InventarioException("El producto '{$producto->nombre}' no admite recetas porque es de tipo {$producto->tipo_producto}.");
        }

        return DB::transaction(function () use ($producto, $dto) {
            // 1. Limpiar receta anterior
            Receta::where('producto_id', $producto->id)->delete();

            $costoTotalReceta = 0.0;

            // 2. Insertar nuevos ingredientes
            foreach ($dto->ingredientes as $item) {
                $ingredienteId = (int) $item['ingrediente_producto_id'];
                $cantidad = (float) $item['cantidad'];

                if ($ingredienteId === $producto->id) {
                    throw new InventarioException("Un producto no puede ser ingrediente de sí mismo.");
                }

                $ingrediente = Producto::findOrFail($ingredienteId);

                Receta::create([
                    'producto_id'             => $producto->id,
                    'ingrediente_producto_id' => $ingredienteId,
                    'cantidad'                => $cantidad,
                ]);

                $costoTotalReceta += $cantidad * (float) $ingrediente->costo;
            }

            // 3. Si es un plato o combo, actualizar automáticamente el costo unitario del producto
            if (in_array($producto->tipo_producto, ['PLATO', 'COMBO'], true) && count($dto->ingredientes) > 0) {
                $producto->costo = round($costoTotalReceta, 4);
                $producto->save();
            }

            return $producto->fresh(['recetas.ingrediente.unidadMedida', 'categoria']);
        });
    }

    /**
     * Calcular el costo total de los ingredientes de un producto basado en su receta
     */
    public function calcularCostoProducto(int $productoId): float
    {
        $producto = Producto::with('recetas.ingrediente')->findOrFail($productoId);

        if (!in_array($producto->tipo_producto, ['PLATO', 'COMBO'], true) || $producto->recetas->isEmpty()) {
            return (float) $producto->costo;
        }

        $costoTotal = 0.0;
        foreach ($producto->recetas as $receta) {
            $costoTotal += (float) $receta->cantidad * (float) ($receta->ingrediente->costo ?? 0.0);
        }

        return round($costoTotal, 4);
    }
}
