<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class FacturaDetalle extends Model
{
    use HasFactory;

    protected $table = 'factura_detalle';

    protected $fillable = [
        'factura_id',
        'producto_id',
        'descripcion',
        'cantidad',
        'precio',
        'itbis',
        'total'
    ];

    public function producto()
    {
        return $this->belongsTo(Producto::class);
    }

    public function factura()
    {
        return $this->belongsTo(Factura::class);
    }
}
