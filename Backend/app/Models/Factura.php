<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Factura extends Model
{
    use HasFactory;

    protected $fillable = [
        'cliente_id',
        'ncf',
        'tipo_factura',
        'fecha_emision',
        'fecha_vencimiento',
        'subtotal',
        'descuento_total',
        'itbis',
        'total',
        'estado',
        'nota',
        'dias_credito',
    ];
public function user() {
    return $this->belongsTo(User::class);
}
     public function cliente() {
            return $this->belongsTo(Cliente::class);
       }

     public function detalles() {
           return $this->hasMany(FacturaDetalle::class);
     }
}
