<?php

declare(strict_types=1);

namespace App\Modules\Contabilidad\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class BulkUpdateConfiguracionContableRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'configs' => 'required|array|min:1',
            'configs.*.id' => 'required|integer|exists:configuraciones_contables,id',
            'configs.*.cuenta_id' => 'nullable|integer|exists:catalogo_cuentas,id',
        ];
    }

    public function messages(): array
    {
        return [
            'configs.required' => 'Debe enviar un arreglo de configuraciones para actualizar.',
            'configs.*.id.required' => 'Cada elemento debe incluir el ID de la configuración.',
            'configs.*.id.exists' => 'Una de las configuraciones indicadas no existe.',
            'configs.*.cuenta_id.exists' => 'Una de las cuentas contables no existe en el catálogo.',
        ];
    }
}
