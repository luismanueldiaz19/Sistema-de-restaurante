<?php

declare(strict_types=1);

namespace App\Modules\Mesa\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class UpdateMesaRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        $mesaId = $this->route('id') ?? $this->route('mesa');

        return [
            'nombre'    => 'sometimes|required|string|max:50|unique:mesas,nombre,' . $mesaId,
            'area'      => 'nullable|string|max:50',
            'capacidad' => 'nullable|integer|min:1|max:50',
            'estado'    => 'nullable|in:Libre,Ocupada,PorCobrar,Inactiva',
        ];
    }
}
