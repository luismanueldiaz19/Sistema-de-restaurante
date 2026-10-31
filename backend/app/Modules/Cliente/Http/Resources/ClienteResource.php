<?php

namespace App\Modules\Cliente\Http\Resources;

use Illuminate\Http\Resources\Json\JsonResource;

class ClienteResource extends JsonResource
{
    /**
     * Transform the resource into an array.
     *
     * @param  \Illuminate\Http\Request  $request
     * @return array
     */
    public function toArray($request)
    {
        return [
            'id' => $this->id,
            'nombre' => $this->nombre,
            'rnc_cedula' => $this->rnc_cedula,
            'email' => $this->email,
            'telefono' => $this->telefono,
            'direccion' => $this->direccion,
            'tipo_cliente' => $this->tipo_cliente,
            'limite_credito' => (float) $this->limite_credito,
            'saldo_actual' => (float) $this->saldo_actual,
            'dias_credito' => (int) $this->dias_credito,
            'cuenta_contable' => $this->cuenta_contable,
            'descuento_fijo' => (float) $this->descuento_fijo,
            'activo' => (bool) $this->activo,
            'notas' => $this->notas,
            'created_at' => $this->created_at ? $this->created_at->toIso8601String() : null,
            'updated_at' => $this->updated_at ? $this->updated_at->toIso8601String() : null,
        ];
    }
}
