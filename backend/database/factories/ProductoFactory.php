<?php

namespace Database\Factories;

use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends \Illuminate\Database\Eloquent\Factories\Factory<\App\Models\Producto>
 */





class ProductoFactory extends Factory
{
    /**
     * Define the model's default state.
     *
     * @return array<string, mixed>
     */
    public function definition() {
        return [
           'nombre' => fake()->words(2, true),
           'tipo_producto' => 'PRODUCTO',
           'tipo_contable' => 'INVENTARIO',
        ];
    }




    ///  funcion para crear un producto de tipo materia prima
    public function materiaPrima() {
        return $this->state(function () {
            return [
                'tipo_producto' => 'MATERIA_PRIMA',
            ];
        });
    }
///  funcion para crear un producto de tipo servicio
 public function servicio() {
    return $this->state(function () {
        return [
            'tipo_producto' => 'SERVICIO',
            'tipo_contable' => 'SERVICIO',
            'maneja_inventario' => false,
        ];
    });
}
}
