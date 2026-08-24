<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class PagoCompra extends Model
{
    use HasFactory;

    protected $table = 'pagos_compras';

    protected $fillable = [
        'cxp_id',
        'monto_pagado',
        'fecha_pago',
        'metodo_pago_id',
        'referencia',
        'cuenta_origen_id',
        'asiento_id',
        'usuario_id',
    ];

    public function cuentaPorPagar()
    {
        return $this->belongsTo(CuentaPorPagar::class, 'cxp_id');
    }

    public function cuentaOrigen()
    {
        return $this->belongsTo(CatalogoCuenta::class, 'cuenta_origen_id');
    }

    public function asiento()
    {
        return $this->belongsTo(AsientoContable::class, 'asiento_id');
    }

    public function usuario()
    {
        return $this->belongsTo(User::class, 'usuario_id');
    }

    public function metodoPago()
    {
        return $this->belongsTo(MetodoPago::class, 'metodo_pago_id');
    }
}
