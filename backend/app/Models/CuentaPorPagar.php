<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class CuentaPorPagar extends Model
{
    use HasFactory;

    protected $table = 'cuentas_por_pagar';

    protected $fillable = [
        'proveedor_id',
        'compra_id',
        'monto_original',
        'balance_pendiente',
        'fecha_vencimiento',
        'estado',
    ];

    public function proveedor()
    {
        return $this->belongsTo(Proveedor::class);
    }

    public function compra()
    {
        return $this->belongsTo(Compra::class);
    }

    public function pagos()
    {
        return $this->hasMany(PagoCompra::class, 'cxp_id');
    }
}
