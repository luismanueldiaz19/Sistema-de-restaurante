<?php

namespace App\Modules\Cliente\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class StoreClienteRequest extends FormRequest
{
    public function authorize()
    {
        return true;
    }

    public function rules()
    {
        return [
            'nombre' => 'required|string|max:255',
            'rnc_cedula' => 'nullable|string|max:20|unique:clientes,rnc_cedula',
            'email' => 'nullable|email|max:255',
            'telefono' => 'nullable|string|max:20',
            'direccion' => 'nullable|string',
            'tipo_cliente' => 'nullable|string|in:consumidor_final,credito,gubernamental,especial',
            'limite_credito' => 'nullable|numeric|min:0',
            'saldo_actual' => 'nullable|numeric',
            'dias_credito' => 'nullable|integer|min:0',
            'cuenta_contable' => 'nullable|string|max:50',
            'descuento_fijo' => 'nullable|numeric|min:0|max:100',
            'activo' => 'boolean',
            'notas' => 'nullable|string',
        ];
    }
}
