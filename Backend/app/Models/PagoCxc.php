<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class PagoCxc extends Model
{
    use HasFactory;

    protected $table = 'pagos_cxc';

    protected $fillable = [
        'cxc_id',
        'monto_pagado',
        'fecha_pago',
        'metodo_pago',
        'referencia',
        'cuenta_destino_id',
        'usuario_id',
        'asiento_id'
    ];

    protected $casts = [
        'fecha_pago' => 'date',
        'monto_pagado' => 'decimal:2',
    ];

    public function cuentaPorCobrar()
    {
        return $this->belongsTo(CuentaPorCobrar::class, 'cxc_id');
    }

    public function cuentaDestino()
    {
        return $this->belongsTo(CatalogoCuenta::class, 'cuenta_destino_id');
    }

    public function usuario()
    {
        return $this->belongsTo(User::class, 'usuario_id');
    }

    public function asientoContable()
    {
        return $this->belongsTo(AsientoContable::class, 'asiento_id');
    }
}
