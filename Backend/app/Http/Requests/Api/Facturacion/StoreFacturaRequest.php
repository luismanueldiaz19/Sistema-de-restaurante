<?php

namespace App\Http\Requests\Api\Facturacion;

use Illuminate\Foundation\Http\FormRequest;

class StoreFacturaRequest extends FormRequest
{
    public function authorize()
    {
        return true;
    }

    public function rules()
    {
        return [
            'cliente_id'               => 'required|exists:clientes,id',
            'ncf_secuencia_id'         => 'required|exists:ncf_secuencias,id',
            'fecha_emision'            => 'required|date',
            'fecha_vencimiento'        => 'nullable|date',
            'dias_credito'             => 'nullable|integer|min:0',
            'nota'                     => 'nullable|string',
            'idempotency_key'          => 'nullable|string|max:36',
            
            // Validar que detalles sea un array con al menos 1 elemento
            'detalles'                 => 'required|array|min:1',
            // Validar los campos internos de CADA detalle
            'detalles.*.producto_id'   => 'nullable|exists:productos,id',
            'detalles.*.descripcion'   => 'required|string|max:255',
            'detalles.*.cantidad'      => 'required|numeric|min:0.01',
            'detalles.*.precio'        => 'required|numeric|min:0',
            'detalles.*.descuento'     => 'nullable|numeric|min:0',
            
            // Validar el pago (si viene)
            'pago'                     => 'nullable|array',
            'pago.monto_pagado'        => 'required_with:pago|numeric|min:0.01',
            'pago.monto_recibido'      => 'required_with:pago|numeric|min:0.01',
            'pago.metodo_pago'         => 'required_with:pago|string',
            'pago.metodo_pago_id'      => 'nullable|exists:metodo_pagos,id',
        ];
    }
}
