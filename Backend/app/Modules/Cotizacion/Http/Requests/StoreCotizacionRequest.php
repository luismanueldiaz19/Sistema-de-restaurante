<?php

declare(strict_types=1);

namespace App\Modules\Cotizacion\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class StoreCotizacionRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user() !== null;
    }

    public function rules(): array
    {
        return [
            'cliente_id' => ['required', 'integer', 'exists:clientes,id'],
            'fecha_emision' => ['required', 'date'],
            'fecha_vencimiento' => ['nullable', 'date'],
            'detalles' => ['required', 'array', 'min:1'],
            'detalles.*.producto_id' => ['nullable', 'integer', 'exists:productos,id'],
            'detalles.*.descripcion' => ['required', 'string'],
            'detalles.*.cantidad' => ['required', 'numeric', 'min:0.01'],
            'detalles.*.precio' => ['required', 'numeric', 'min:0'],
            'detalles.*.itbis_porcentaje' => ['nullable', 'numeric', 'min:0'],
            'detalles.*.descuento' => ['nullable', 'numeric', 'min:0'],
            'detalles.*.descuento_porcentaje' => ['nullable', 'numeric', 'min:0'],
            'nota' => ['nullable', 'string'],
            'company_name' => ['nullable', 'string'],
            'company_rnc' => ['nullable', 'string'],
            'company_address' => ['nullable', 'string'],
            'company_phone' => ['nullable', 'string'],
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
