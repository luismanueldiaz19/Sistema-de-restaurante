<?php

declare(strict_types=1);

namespace App\Modules\Contabilidad\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class UpdateConfiguracionContableRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'cuenta_id' => 'nullable|exists:catalogo_cuentas,id',
        ];
    }

    public function messages(): array
    {
        return [
            'cuenta_id.exists' => 'La cuenta contable seleccionada no existe en el catálogo.',
        ];
    }
}
