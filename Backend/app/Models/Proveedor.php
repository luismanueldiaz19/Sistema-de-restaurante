<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Proveedor extends Model
{
    use HasFactory;

    protected $table = 'proveedores';

    protected $fillable = [
        'nombre',
        'rnc',
        'telefono',
        'email',
        'direccion',
        'cuenta_contable_cxp_id',
        'cuenta_contable_gasto_id',
        'activo',
    ];

    protected $casts = [
        'activo' => 'boolean',
    ];

    public function cuentaCxp()
    {
        return $this->belongsTo(CatalogoCuenta::class, 'cuenta_contable_cxp_id');
    }

    public function cuentaGasto()
    {
        return $this->belongsTo(CatalogoCuenta::class, 'cuenta_contable_gasto_id');
    }

    public function compras()
    {
        return $this->hasMany(Compra::class);
    }
}
