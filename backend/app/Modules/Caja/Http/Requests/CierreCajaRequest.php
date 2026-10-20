<?php

declare(strict_types=1);

namespace App\Modules\Caja\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class CierreCajaRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user() !== null;
    }

    public function rules(): array
    {
        return [
            'monto_final_fisico' => ['required', 'numeric', 'min:0'],
            'desglose'           => ['nullable', 'array'],
            'comentario'         => ['nullable', 'string', 'max:500'],
        ];
    }

    protected function failedValidation(\Illuminate\Contracts\Validation\Validator $validator)
    {
        $errors = $validator->errors()->all();
        throw new \Illuminate\Http\Exceptions\HttpResponseException(
            response()->json([
                'success' => false,
                'message' => 'Error de validación: ' . implode(', ', $errors),
                'data'    => $validator->errors()
            ], 422)
        );
    }
}
