<?php

declare(strict_types=1);

namespace App\Modules\Caja\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class AperturaCajaRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user() !== null; // O verificar permiso de cajero
    }

    public function rules(): array
    {
        return [
            'caja_id' => ['required', 'integer', 'exists:cajas,id'],
            'turno_id' => ['required', 'integer', 'exists:turnos,id'],
            'monto_inicial' => ['required', 'numeric', 'min:0'],
        ];
    }

    protected function failedValidation(\Illuminate\Contracts\Validation\Validator $validator)
    {
        $errors = $validator->errors()->all();
        throw new \Illuminate\Http\Exceptions\HttpResponseException(
            response()->json([
                'success' => false,
                'message' => 'Error de validación: ' . implode(', ', $errors),
                'data' => $validator->errors()
            ], 422)
        );
    }
}
