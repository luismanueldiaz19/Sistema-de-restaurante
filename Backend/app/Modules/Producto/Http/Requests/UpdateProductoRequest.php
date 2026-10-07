<?php

declare(strict_types=1);

namespace App\Modules\Producto\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;
use App\Models\Producto;

class UpdateProductoRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user() && $this->user()->can('update', Producto::class);
    }

    public function rules(): array
    {
        $id = $this->route('producto');

        return [
            'nombre' => ['sometimes', 'required', 'string', 'max:255'],
            'codigo' => ['nullable', 'string', 'max:100', 'unique:productos,codigo,' . $id],
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
            'stock_actual' => ['nullable', 'numeric'],
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

    protected function failedValidation(\Illuminate\Contracts\Validation\Validator $validator)
    {
        $errors = $validator->errors()->all();
        throw new \Illuminate\Http\Exceptions\HttpResponseException(
            response()->json([
                'success' => false,
                'message' => 'Error de validación: ' . implode(', ', $errors),
                'data' => $validator->errors()
            ], 422)
        );
    }
}
