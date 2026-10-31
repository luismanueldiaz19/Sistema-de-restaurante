<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class CuentaPorCobrar extends Model
{
    use HasFactory;

    protected $table = 'cuentas_por_cobrar';

    protected $fillable = [
        'cliente_id',
        'factura_id',
        'monto_original',
        'balance_pendiente',
        'fecha_emision',
        'fecha_vencimiento',
        'estado',
        'descripcion'
    ];

    protected $casts = [
        'fecha_emision' => 'date',
        'fecha_vencimiento' => 'date',
        'monto_original' => 'decimal:2',
        'balance_pendiente' => 'decimal:2',
    ];

    public function cliente()
    {
        return $this->belongsTo(Cliente::class);
    }

    public function factura()
    {
        return $this->belongsTo(Factura::class);
    }

    public function pagos()
    {
        return $this->hasMany(PagoCxc::class, 'cxc_id');
    }
}
