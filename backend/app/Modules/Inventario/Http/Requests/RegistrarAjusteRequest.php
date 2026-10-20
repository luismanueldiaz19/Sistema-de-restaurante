<?php

declare(strict_types=1);

namespace App\Modules\Inventario\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class RegistrarAjusteRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'producto_id' => ['required', 'integer', 'exists:productos,id'],
            'tipo'        => ['required', 'string', 'in:ENTRADA,SALIDA'],
            'cantidad'    => ['required', 'numeric', 'min:0.0001'],
            'motivo'      => ['required', 'string', 'max:255'],
        ];
    }

    protected function failedValidation(\Illuminate\Contracts\Validation\Validator $validator)
    {
        $errors = $validator->errors()->all();
        throw new \Illuminate\Http\Exceptions\HttpResponseException(
            response()->json([
                'success' => false,
                'message' => 'Error de validación: ' . implode(', ', $errors),
                'errors'  => $validator->errors()
            ], 422)
        );
    }
}
