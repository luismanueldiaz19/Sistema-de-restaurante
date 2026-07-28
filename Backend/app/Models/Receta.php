<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Receta extends Model
{
    use HasFactory;

    protected $fillable = [
        'producto_id',
        'ingrediente_producto_id',
        'cantidad'
    ];

    protected $casts = [
        'cantidad' => 'double'
    ];

    public function producto()
    {
        return $this->belongsTo(Producto::class);
    }

    public function ingrediente()
    {
        return $this->belongsTo(Producto::class, 'ingrediente_producto_id');
    }
}
