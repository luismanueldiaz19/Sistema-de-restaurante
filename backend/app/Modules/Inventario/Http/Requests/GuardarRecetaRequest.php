<?php

declare(strict_types=1);

namespace App\Modules\Inventario\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class GuardarRecetaRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'ingredientes'                                  => ['present', 'array'],
            'ingredientes.*.ingrediente_producto_id'        => ['required', 'integer', 'exists:productos,id'],
            'ingredientes.*.cantidad'                       => ['required', 'numeric', 'min:0.0001'],
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
