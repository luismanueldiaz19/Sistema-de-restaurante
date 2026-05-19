<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class ConfiguracionContable extends Model
{
    use HasFactory;

    protected $table = 'configuraciones_contables';

    protected $fillable = [
        'clave',
        'nombre',
        'grupo',
        'cuenta_id',
    ];

    public function cuenta()
    {
        return $this->belongsTo(CatalogoCuenta::class, 'cuenta_id');
    }
}
