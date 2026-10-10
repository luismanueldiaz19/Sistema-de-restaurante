<?php

declare(strict_types=1);

namespace App\Modules\Compra\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;
use App\Modules\Compra\Enums\CompraTipoEnum;
use Illuminate\Validation\Rule;

class StoreCompraRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user() !== null;
    }

    public function rules(): array
    {
        return [
            'proveedor_id'                  => ['required', 'integer', 'exists:proveedores,id'],
            'numero_factura_proveedor'      => ['required', 'string'],
            'ncf'                           => ['nullable', 'string'],
            'fecha_compra'                  => ['required', 'date'],
            'fecha_vencimiento'             => ['nullable', 'date'],
            'tipo_compra'                   => ['required', Rule::enum(CompraTipoEnum::class)],
            'metodo_pago_id'                => ['nullable', 'integer', 'exists:metodo_pagos,id'],
            'referencia_pago'               => ['nullable', 'string'],
            'referencia'                    => ['nullable', 'string'],
            'notas'                         => ['nullable', 'string'],
            'idempotency_key'               => ['nullable', 'string', 'max:36'],
            
            'detalles'                      => ['required', 'array', 'min:1'],
            'detalles.*.producto_id'        => ['nullable', 'integer', 'exists:productos,id'],
            'detalles.*.descripcion'        => ['nullable', 'string'],
            'detalles.*.cuenta_contable_id' => ['nullable', 'integer', 'exists:catalogo_cuentas,id'],
            'detalles.*.presentacion'       => ['nullable', 'string'],
            'detalles.*.factor_conversion'  => ['nullable', 'numeric', 'min:0.01'],
            'detalles.*.cantidad'           => ['required', 'numeric', 'min:0.01'],
            'detalles.*.costo_unitario'     => ['required', 'numeric', 'min:0'],
            'detalles.*.impuesto_monto'     => ['required', 'numeric', 'min:0'],
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
