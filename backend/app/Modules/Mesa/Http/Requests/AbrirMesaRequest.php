<?php

declare(strict_types=1);

namespace App\Modules\Mesa\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class AbrirMesaRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'cliente_nombre'             => 'nullable|string|max:100',
            'cliente_telefono'           => 'nullable|string|max:20',
            'mesero'                     => 'nullable|string|max:100',
            'nota'                       => 'nullable|string',
            'detalles'                   => 'required|array|min:1',
            'detalles.*.producto_id'     => 'required|exists:productos,id',
            'detalles.*.nombre_producto' => 'required|string',
            'detalles.*.cantidad'        => 'required|numeric|min:0.01',
            'detalles.*.precio_unitario' => 'required|numeric|min:0',
        ];
    }
}
