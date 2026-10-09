<?php
declare(strict_types=1);

namespace App\Modules\CuentaPorCobrar\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class RegistrarCobroRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'monto_pagado'    => 'required|numeric|min:0.01',
            'fecha_pago'      => 'required|date',
            'metodo_pago_id'  => 'required|exists:metodo_pagos,id',
            'referencia'      => 'nullable|string',
            'idempotency_key' => 'nullable|string|max:36',
        ];
    }
}
