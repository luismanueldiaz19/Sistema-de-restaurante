<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Ingrediente extends Model
{
    use HasFactory;

    protected $fillable = [
        'nombre',
        'unidad',
        'stock',
        'costo_unitario'
    ];

    protected $casts = [
        'stock' => 'double',
        'costo_unitario' => 'double'
    ];

    public function recetas()
    {
        return $this->hasMany(Receta::class);
    }

    public function movimientos()
    {
        return $this->hasMany(MovimientoInventario::class);
    }
}
