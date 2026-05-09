<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Pago extends Model
{
    protected $fillable = [
        'factura_id',
        'user_id',
        'caja_sesion_id',
        'monto_pagado',
        'monto_recibido',
        'devuelta',
        'metodo_pago',
        'referencia_pago',
        'fecha_pago',
    ];

    public function factura()
    {
        return $this->belongsTo(Factura::class);
    }
