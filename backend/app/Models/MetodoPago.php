<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class MetodoPago extends Model
{
    use HasFactory;

    protected $fillable = [
        'nombre',
        'tipo',
        'catalogo_cuenta_id',
        'bank_account_id',
        'activo'
    ];

    public function cuentaContable()
    {
        return $this->belongsTo(CatalogoCuenta::class, 'catalogo_cuenta_id');
    }

    public function bankAccount()
    {
        return $this->belongsTo(BankAccount::class, 'bank_account_id');
    }
}
