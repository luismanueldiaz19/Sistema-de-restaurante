<?php

namespace App\Modules\Cliente\Models;

use Illuminate\Database\Eloquent\Model;

class Cliente extends Model
{
    /**
     * Define the table name (optional, but good practice).
     */
    protected $table = 'clientes';

    /**
     * The attributes that are mass assignable.
     */
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
