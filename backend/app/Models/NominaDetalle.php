<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class NominaDetalle extends Model
{
    use HasFactory;

    protected $fillable = [
        'nomina_id',
        'empleado_id',
        'nombre_empleado',
        'salario_bruto',
        'afp_empleado',
        'sfs_empleado',
        'isr_retencion',
        'otros_descuentos',
        'salario_neto',
    ];

    protected $casts = [
        'salario_bruto' => 'decimal:2',
        'afp_empleado' => 'decimal:2',
        'sfs_empleado' => 'decimal:2',
        'isr_retencion' => 'decimal:2',
        'otros_descuentos' => 'decimal:2',
        'salario_neto' => 'decimal:2',
    ];

    public function nomina()
    {
        return $this->belongsTo(Nomina::class);
    }

    public function empleado()
    {
        return $this->belongsTo(Empleado::class);
    }
}
