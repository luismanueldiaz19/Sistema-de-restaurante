<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class CatalogoCuenta extends Model
{
    use HasFactory;

    protected $table = 'catalogo_cuentas';

    protected $fillable = [
        'codigo',
        'nombre',
        'tipo',
        'nivel',
        'padre_id',
        'permite_movimiento',
    ];

    public function padre()
    {
        return $this->belongsTo(CatalogoCuenta::class, 'padre_id');
    }

    public function hijos()
    {
        return $this->hasMany(CatalogoCuenta::class, 'padre_id');
    }
}
