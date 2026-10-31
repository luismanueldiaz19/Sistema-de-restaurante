<?php

namespace App\Modules\Cliente\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class UpdateClienteRequest extends FormRequest
{
    public function authorize()
    {
        return true;
    }

    public function rules()
    {
        // El ID del cliente lo sacamos del route param
        $clienteId = $this->route('cliente');

        return [
            'nombre' => 'sometimes|required|string|max:255',
            'rnc_cedula' => [
                'nullable',
                'string',
                'max:20',
                Rule::unique('clientes', 'rnc_cedula')->ignore($clienteId),
            ],
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
