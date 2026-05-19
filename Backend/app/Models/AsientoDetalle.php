<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class AsientoDetalle extends Model
{
    use HasFactory;

    protected $table = 'asiento_detalles';

    protected $fillable = [
        'asiento_id',
        'cuenta_id',
        'debito',
        'credito',
    ];

    public function asiento()
    {
        return $this->belongsTo(AsientoContable::class, 'asiento_id');
    }

    public function cuenta()
    {
        return $this->belongsTo(CatalogoCuenta::class, 'cuenta_id');
    }
}
