<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class CompraDetalle extends Model
{
    use HasFactory;

    protected $table = 'compra_detalles';

    protected $fillable = [
        'compra_id',
        'producto_id',
        'descripcion',
        'cuenta_contable_id',
        'cantidad',
        'costo_unitario',
        'subtotal',
        'impuesto_monto',
        'total',
    ];

    public function compra()
    {
        return $this->belongsTo(Compra::class);
    }

    public function producto()
    {
        return $this->belongsTo(Producto::class);
    }

    public function cuentaContable()
    {
        return $this->belongsTo(CatalogoCuenta::class, 'cuenta_contable_id');
    }
}
