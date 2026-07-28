<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class MovimientoInventario extends Model
{
    use HasFactory;

    protected $table = 'movimientos_inventario';

    protected $fillable = [
        'producto_id',
        'tipo',
        'cantidad',
        'referencia',
        'fecha'
    ];

    protected $casts = [
        'cantidad' => 'double',
        'fecha' => 'datetime'
    ];

    public function producto()
    {
        return $this->belongsTo(Producto::class);
    }
}
