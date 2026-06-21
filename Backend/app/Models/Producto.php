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
        'categoria_id',
        'marca_id',
        'unidad_medida_id',
        'impuesto_id',
        'impuesto_venta_id',
        'impuesto_compra_id',
        'tipo_producto',
        'tipo_contable',
        'precio_venta',
        'ultimo_costo',
        'costo_promedio',
        'precio_incluye_impuesto',
        'maneja_inventario',
        'maneja_vencimiento',
        'stock_actual',
        'stock_minimo',
        'cuenta_ingreso_id',
        'cuenta_inventario_id',
        'cuenta_costo_id',
        'activo',
    ];

    protected $casts = [
        'precio_venta' => 'double',
        'ultimo_costo' => 'double',
        'costo_promedio' => 'double',
        'precio_incluye_impuesto' => 'boolean',
        'maneja_inventario' => 'boolean',
        'maneja_vencimiento' => 'boolean',
        'stock_actual' => 'double',
        'stock_minimo' => 'double',
        'activo' => 'boolean',
    ];

    public function categoria()
    {
        return $this->belongsTo(Categoria::class);
    }

    public function marca()
    {
        return $this->belongsTo(Marca::class);
    }

    public function unidadMedida()
    {
        return $this->belongsTo(UnidadMedida::class);
    }

    public function impuesto()
    {
        return $this->belongsTo(Impuesto::class);
    }

    public function impuestoVenta()
    {
        return $this->belongsTo(Impuesto::class, 'impuesto_venta_id');
    }

    public function impuestoCompra()
    {
        return $this->belongsTo(Impuesto::class, 'impuesto_compra_id');
    }

    public function recetas()
    {
        return $this->hasMany(Receta::class);
    }
}
