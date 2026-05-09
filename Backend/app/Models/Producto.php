<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Producto extends Model
{
    use HasFactory;

    protected $fillable = [
        'nombre',
        'codigo',
        'descripcion',
        'categoria',
        'tipo_producto',
        'unidad_medida',
        'precio_venta',
        'costo',
        'itbis_porcentaje',
        'maneja_inventario',
        'stock_actual',
        'stock_minimo',
        'cuenta_contable_ingresos',
        'cuenta_contable_inventario',
        'cuenta_contable_costos',
        'activo',
    ];

    protected $casts = [
        'precio_venta' => 'double',
        'costo' => 'double',
        'itbis_porcentaje' => 'double',
        'maneja_inventario' => 'boolean',
        'stock_actual' => 'double',
        'stock_minimo' => 'double',
        'activo' => 'boolean',
    ];

    public function setUnidadMedidaAttribute($value)
    {
        $this->attributes['unidad_medida'] = strtoupper($value);
    }
    public function recetas()
    {
        return $this->hasMany(Receta::class);
    }
}
