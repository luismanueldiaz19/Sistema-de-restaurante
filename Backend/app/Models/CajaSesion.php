<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class CajaSesion extends Model
{
    use HasFactory;

    protected $table = 'caja_sesiones';

    protected $fillable = [
        'caja_id',
        'user_id',
        'turno_id',
        'monto_inicial',
        'monto_final_esperado',
        'monto_final_fisico',
        'diferencia',
        'estado',
        'fecha_apertura',
        'fecha_cierre',
        'comentario'
    ];

    protected $casts = [
        'fecha_apertura' => 'datetime',
        'fecha_cierre' => 'datetime',
    ];

    public function caja()
    {
        return $this->belongsTo(Caja::class);
    }

    public function usuario()
    {
        return $this->belongsTo(User::class, 'user_id');
    }

    public function turno()
    {
        return $this->belongsTo(Turno::class);
    }

    // Relación con las facturas emitidas en esta sesión
    public function facturas()
    {
        return $this->hasMany(Factura::class, 'caja_sesion_id');
    }
}
