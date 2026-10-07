<?php

declare(strict_types=1);

namespace App\Modules\Producto\Http\Resources;

use Illuminate\Http\Resources\Json\JsonResource;

class ProductoResource extends JsonResource
{
    public function toArray($request): array
    {
        return [
            'id' => $this->id,
            'nombre' => $this->nombre,
            'codigo' => $this->codigo,
            'descripcion' => $this->descripcion,
            'categoria_id' => $this->categoria_id,
            'marca_id' => $this->marca_id,
            'unidad_medida_id' => $this->unidad_medida_id,
            'impuesto_id' => $this->impuesto_id,
            'categoria' => $this->whenLoaded('categoria'),
            'marca' => $this->whenLoaded('marca'),
            'unidad_medida' => $this->whenLoaded('unidadMedida'),
            'impuesto' => $this->whenLoaded('impuesto'),
            'tipo_producto' => $this->tipo_producto,
            'tipo_contable' => $this->tipo_contable,
            'precio_venta' => (float) $this->precio_venta,
            'precio_compra' => (float) $this->precio_compra,
            'costo' => (float) $this->costo,
            'maneja_inventario' => (bool) $this->maneja_inventario,
            'stock_actual' => (float) $this->stock_actual,
            'stock_minimo' => (float) $this->stock_minimo,
            'cuenta_ingreso_id' => $this->cuenta_ingreso_id,
            'cuenta_inventario_id' => $this->cuenta_inventario_id,
            'cuenta_costo_id' => $this->cuenta_costo_id,
            'cuenta_gasto_id' => $this->cuenta_gasto_id,
            'activo' => (bool) $this->activo,
            'presentacion_compra_por_defecto' => $this->presentacion_compra_por_defecto,
            'factor_compra_por_defecto' => $this->factor_compra_por_defecto ? (float) $this->factor_compra_por_defecto : null,
            'created_at' => $this->created_at,
            'updated_at' => $this->updated_at,
        ];
    }
}
