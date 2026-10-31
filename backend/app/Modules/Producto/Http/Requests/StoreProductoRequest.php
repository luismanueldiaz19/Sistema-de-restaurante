<?php

declare(strict_types=1);

namespace App\Modules\Producto\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class StoreProductoRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    protected function prepareForValidation(): void
    {
        if ($this->has('nombre') && is_string($this->nombre)) {
            $nombreLimpio = preg_replace('/\s+/', ' ', trim($this->nombre));
            $this->merge([
                'nombre' => mb_strtoupper((string) $nombreLimpio, 'UTF-8'),
            ]);
        }

        if ($this->has('codigo')) {
            $codigo = is_string($this->codigo) ? trim($this->codigo) : '';
            $this->merge([
                'codigo' => $codigo !== '' ? mb_strtoupper($codigo, 'UTF-8') : null,
            ]);
        }
    }

    public function rules(): array
    {
        return [
            'nombre' => ['required', 'string', 'max:255', 'unique:productos,nombre'],
            'codigo' => ['nullable', 'string', 'max:100', 'unique:productos,codigo'],
            'descripcion' => ['nullable', 'string'],
            'categoria_id' => ['nullable', 'integer', 'exists:categorias,id'],
            'marca_id' => ['nullable', 'integer', 'exists:marcas,id'],
            'unidad_medida_id' => ['nullable', 'integer', 'exists:unidades_medida,id'],
            'impuesto_id' => ['nullable', 'integer', 'exists:impuestos,id'],
            'tipo_producto' => ['nullable', 'string', \Illuminate\Validation\Rule::enum(\App\Modules\Producto\Enums\TipoProductoEnum::class)],
            'tipo_contable' => ['nullable', 'string', \Illuminate\Validation\Rule::enum(\App\Modules\Producto\Enums\TipoContableEnum::class)],
            'precio_venta' => ['nullable', 'numeric', 'min:0'],
            'precio_compra' => ['nullable', 'numeric', 'min:0'],
            'costo' => ['nullable', 'numeric', 'min:0'],
            'maneja_inventario' => ['nullable', 'boolean'],
            'stock_actual' => ['nullable', 'numeric', 'min:0'],
            'stock_minimo' => ['nullable', 'numeric', 'min:0'],
            'cuenta_ingreso_id' => ['nullable', 'integer'],
            'cuenta_inventario_id' => ['nullable', 'integer'],
            'cuenta_costo_id' => ['nullable', 'integer'],
            'cuenta_gasto_id' => ['nullable', 'integer'],
            'activo' => ['nullable', 'boolean'],
            'presentacion_compra_por_defecto' => ['nullable', 'string', 'max:100'],
            'factor_compra_por_defecto' => ['nullable', 'numeric', 'min:0'],
        ];
    }

    public function messages(): array
    {
        return [
            'nombre.required' => 'El nombre del producto es obligatorio.',
            'nombre.unique' => 'Ya existe un producto con este nombre.',
            'codigo.unique' => 'Ya existe un producto con este código.',
            'stock_actual.min' => 'La cantidad de stock no puede ser negativa.',
            'stock_minimo.min' => 'El stock mínimo no puede ser negativo.',
            'precio_venta.min' => 'El precio de venta no puede ser negativo.',
            'costo.min' => 'El costo no puede ser negativo.',
        ];
    }

    protected function failedValidation(\Illuminate\Contracts\Validation\Validator $validator)
    {
        $errors = $validator->errors()->all();
        throw new \Illuminate\Http\Exceptions\HttpResponseException(
            response()->json([
                'success' => false,
                'message' => implode(' ', $errors),
                'data' => $validator->errors()
            ], 422)
        );
    }
}
