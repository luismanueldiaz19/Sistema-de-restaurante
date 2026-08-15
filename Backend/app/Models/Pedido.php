<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Pedido extends Model
{
    use HasFactory;

    protected $fillable = [
        'secuencia_diaria',
        'fecha',
        'cliente_nombre',
        'cliente_telefono',
        'direccion',
        'tipo_entrega',
        'estado',
        'total',
        'nota',
        'factura_id',
        'codigo_barras',
    ];

    public function detalles()
    {
        return $this->hasMany(PedidoDetalle::class, 'pedido_id');
    }

    public function factura()
    {
        return $this->belongsTo(Factura::class, 'factura_id');
    }
}
