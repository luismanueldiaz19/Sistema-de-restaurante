<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Compra extends Model
{
    use HasFactory;

    protected $table = 'compras';

    protected $fillable = [
        'proveedor_id',
        'orden_compra_id',
        'numero_factura_proveedor',
        'ncf',
        'fecha_compra',
        'fecha_vencimiento',
        'tipo_compra',
        'subtotal',
        'impuestos',
        'total',
        'estado',
        'usuario_id',
        'asiento_id',
        'notas',
    ];

    public function proveedor()
    {
        return $this->belongsTo(Proveedor::class);
    }

    public function detalles()
    {
        return $this->hasMany(CompraDetalle::class);
    }

    public function ordenCompra()
    {
        return $this->belongsTo(OrdenCompra::class);
    }

    public function usuario()
    {
        return $this->belongsTo(User::class, 'usuario_id');
    }

    public function asiento()
    {
        return $this->belongsTo(AsientoContable::class, 'asiento_id');
    }

    public function cuentaPorPagar()
    {
        return $this->hasOne(CuentaPorPagar::class);
    }
}
