<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class DevolucionCompra extends Model
{
    use HasFactory;

    protected $table = 'devoluciones_compras';

    protected $fillable = [
        'compra_id',
        'fecha_devolucion',
        'motivo',
        'total_devuelto',
        'asiento_id',
        'usuario_id',
    ];

    public function compra()
    {
        return $this->belongsTo(Compra::class);
    }

    public function asiento()
    {
        return $this->belongsTo(AsientoContable::class, 'asiento_id');
    }

    public function usuario()
    {
        return $this->belongsTo(User::class, 'usuario_id');
    }
}
