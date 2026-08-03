<?php

namespace Database\Factories;

use Illuminate\Database\Eloquent\Factories\Factory;
use App\Models\Producto;

/**
 * @extends \Illuminate\Database\Eloquent\Factories\Factory<\App\Models\Receta>
 */
class RecetaFactory extends Factory
{
    /**
     * Define the model's default state.
     *
     * @return array<string, mixed>
     */
    public function definition()
    {
        return [
           'producto_id' => Producto::factory(),
           'ingrediente_producto_id' => Producto::factory(),
           'cantidad' => $this->faker -> numberBetween(1, 10),
           
        ];
    }
}
