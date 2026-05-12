<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Empleado extends Model
{
    use HasFactory;

    protected $fillable = [
        'nombre',
        'cedula',
        'salario_base',
        'tipo_nomina',
        'turno',
        'fecha_ingreso',
        'cargo',
        'activo',
    ];

    protected $casts = [
        'fecha_ingreso' => 'date',
        'activo' => 'boolean',
        'salario_base' => 'decimal:2',
    ];
}
