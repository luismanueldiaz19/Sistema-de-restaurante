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
        'descripcion',
        'cantidad',
        'precio',
        'itbis',
        'subtotal'
    ];

    public function factura()
    {
        return $this->belongsTo(Factura::class);
    }
}
