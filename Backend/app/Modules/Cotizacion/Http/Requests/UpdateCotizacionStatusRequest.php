<?php

declare(strict_types=1);

namespace App\Modules\Cotizacion\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class UpdateCotizacionStatusRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user() !== null;
    }

    public function rules(): array
    {
        return [
            'estado' => ['required', \Illuminate\Validation\Rule::enum(\App\Modules\Cotizacion\Enums\CotizacionEstadoEnum::class)],
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
