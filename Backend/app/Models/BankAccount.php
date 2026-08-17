<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class BankAccount extends Model
{
    use HasFactory;

    protected $fillable = [
        'bank_id',
        'name',
        'account_number',
        'currency',
        'current_balance',
        'accounting_account_id',
        'is_active',
    ];

    protected $casts = [
        'current_balance' => 'decimal:2',
        'is_active' => 'boolean',
    ];

    public function bank()
    {
        return $this->belongsTo(Bank::class);
    }

    public function accountingAccount()
    {
        return $this->belongsTo(CatalogoCuenta::class, 'accounting_account_id');
    }

    public function transactions()
    {
        return $this->hasMany(BankTransaction::class);
    }
}
