<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Nomina extends Model
{
    use HasFactory;

    protected $fillable = [
        'periodo',
        'fecha_creacion',
        'estado',
        'total_bruto',
        'total_retenciones',
        'total_neto',
    ];

    protected $casts = [
        'fecha_creacion' => 'date',
        'total_bruto' => 'decimal:2',
        'total_retenciones' => 'decimal:2',
        'total_neto' => 'decimal:2',
    ];

    public function detalles()
    {
        return $this->hasMany(NominaDetalle::class);
    }
}
