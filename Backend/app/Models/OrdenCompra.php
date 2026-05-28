<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class OrdenCompra extends Model
{
    use HasFactory;

    protected $table = 'ordenes_compra';

    protected $fillable = [
        'proveedor_id',
        'numero_orden',
        'fecha',
        'total',
        'estado',
        'notas',
        'usuario_id',
    ];

    public function proveedor()
    {
        return $this->belongsTo(Proveedor::class);
    }

    public function detalles()
    {
        return $this->hasMany(OrdenCompraDetalle::class);
    }

    public function compras()
    {
        return $this->hasMany(Compra::class, 'orden_compra_id');
    }

    public function usuario()
    {
        return $this->belongsTo(User::class, 'usuario_id');
    }
}
