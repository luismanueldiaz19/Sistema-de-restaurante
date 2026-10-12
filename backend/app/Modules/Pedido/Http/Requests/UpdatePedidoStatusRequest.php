<?php

declare(strict_types=1);

namespace App\Modules\Pedido\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class UpdatePedidoStatusRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'estado' => ['required', 'string', 'in:Pendiente,Confirmado,Preparando,Facturado,Cancelado'],
        ];
    }

    protected function failedValidation(\Illuminate\Contracts\Validation\Validator $validator)
    {
        throw new \Illuminate\Http\Exceptions\HttpResponseException(
            response()->json([
                'success' => false,
                'message' => 'Error de validación: ' . implode(', ', $validator->errors()->all()),
                'errors' => $validator->errors()
            ], 422)
        );
    }
}
