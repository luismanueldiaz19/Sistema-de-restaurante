<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Cliente extends Model
{
    use HasFactory;

    protected $fillable = [
        'nombre',
        'rnc_cedula',
        'email',
        'telefono',
        'direccion',
        'tipo_cliente',
        'limite_credito',
        'saldo_actual',
        'dias_credito',
        'cuenta_contable',
        'descuento_fijo',
        'activo',
        'notas',
    ];
}
