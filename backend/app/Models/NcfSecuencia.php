<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class NcfSecuencia extends Model
{
    use HasFactory;

     protected $table = 'ncf_secuencias';

    protected $fillable = [
        'tipo',
        'nombre',
        'prefijo',
        'actual',
        'rango_inicio',
        'rango_fin',
        'activo',
    ];

    protected $casts = [
        'activo' => 'boolean',
    ];

    
}
