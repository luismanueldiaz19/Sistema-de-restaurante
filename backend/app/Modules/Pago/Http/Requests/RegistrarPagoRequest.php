<?php
declare(strict_types=1);

namespace App\Modules\Pago\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class RegistrarPagoRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'monto_pagado'    => 'required|numeric|min:0.01',
            'monto_recibido'  => 'nullable|numeric|min:0',
            'devuelta'        => 'nullable|numeric|min:0',
            'metodo_pago'     => 'nullable|string',
            'metodo_pago_id'  => 'nullable|exists:metodo_pagos,id',
            'referencia_pago' => 'nullable|string',
            'fecha_pago'      => 'nullable|date',
            'caja_sesion_id'  => 'nullable|exists:caja_sesiones,id',
            'idempotency_key' => 'nullable|string|max:36',
        ];
    }
}
