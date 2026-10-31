<?php

namespace App\Http\Requests\Api\Finanzas;

use Illuminate\Foundation\Http\FormRequest;

class RegistrarCobroRequest extends FormRequest
{
    public function authorize()
    {
        return true; // Asumimos que el auth middleware ya protegió la ruta
    }

    public function rules()
    {
        return [
            'monto_pagado'   => 'required|numeric|min:0.01',
            'fecha_pago'     => 'required|date',
            'metodo_pago_id' => 'required|exists:metodo_pagos,id',
            'referencia'     => 'nullable|string|max:255',
        ];
    }
}
