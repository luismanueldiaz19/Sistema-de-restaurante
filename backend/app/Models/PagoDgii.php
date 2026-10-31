<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class PagoDgii extends Model
{
    use HasFactory;

    protected $table = 'pagos_dgii';

    protected $fillable = [
        'fecha_pago',
        'monto_pagado',
        'periodo_mes',
        'periodo_anio',
        'referencia',
        'cuenta_origen_id',
        'usuario_id',
        'asiento_id',
    ];

    public function cuentaOrigen()
    {
        return $this->belongsTo(CatalogoCuenta::class, 'cuenta_origen_id');
    }

    public function usuario()
    {
        return $this->belongsTo(User::class, 'usuario_id');
    }

    public function asiento()
    {
        return $this->belongsTo(AsientoContable::class, 'asiento_id');
    }
}
