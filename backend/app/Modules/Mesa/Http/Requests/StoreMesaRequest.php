<?php

declare(strict_types=1);

namespace App\Modules\Mesa\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class StoreMesaRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'nombre'    => 'required|string|max:50|unique:mesas,nombre',
            'area'      => 'nullable|string|max:50',
            'capacidad' => 'nullable|integer|min:1|max:50',
        ];
    }
}
