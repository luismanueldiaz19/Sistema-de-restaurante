<?php

declare(strict_types=1);

namespace App\Modules\Contabilidad\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class StoreAsientoManualRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'fecha' => 'required|date',
            'glosa' => 'required|string|max:255',
            'referencia' => 'nullable|string|max:255',
            'detalles' => 'required|array|min:2', // Al menos un débito y un crédito
            'detalles.*.cuenta_id' => 'required|exists:catalogo_cuentas,id',
            'detalles.*.debito' => 'nullable|numeric|min:0',
            'detalles.*.credito' => 'nullable|numeric|min:0',
        ];
    }

    public function withValidator($validator): void
    {
        $validator->after(function ($validator) {
            $detalles = $this->input('detalles', []);
            $totalDebito = 0.0;
            $totalCredito = 0.0;

            foreach ($detalles as $detalle) {
                $totalDebito += (float) ($detalle['debito'] ?? 0);
                $totalCredito += (float) ($detalle['credito'] ?? 0);
            }

            if (abs($totalDebito - $totalCredito) > 0.05) {
                $validator->errors()->add('detalles', "El asiento no cuadra. Total Débito: {$totalDebito}, Total Crédito: {$totalCredito}");
            }
        });
    }
}
