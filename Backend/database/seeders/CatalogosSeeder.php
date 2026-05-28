<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\Categoria;
use App\Models\Marca;
use App\Models\UnidadMedida;
use App\Models\Impuesto;

class CatalogosSeeder extends Seeder
{
    public function run()
    {
        // Categorias
        Categoria::create(['nombre' => 'Comida', 'descripcion' => 'Alimentos preparados', 'activo' => true]);
        Categoria::create(['nombre' => 'Bebidas', 'descripcion' => 'Bebidas frías y calientes', 'activo' => true]);
        Categoria::create(['nombre' => 'Postres', 'descripcion' => 'Dulces y postres', 'activo' => true]);
        Categoria::create(['nombre' => 'Servicios', 'descripcion' => 'Servicios varios', 'activo' => true]);

        // Marcas
        Marca::create(['nombre' => 'Generica', 'descripcion' => 'Marca genérica', 'activo' => true]);
        Marca::create(['nombre' => 'Coca Cola', 'descripcion' => 'Refrescos', 'activo' => true]);

        // Unidades de Medida
        UnidadMedida::create(['nombre' => 'Unidad', 'abreviatura' => 'UND', 'activo' => true]);
        UnidadMedida::create(['nombre' => 'Libra', 'abreviatura' => 'LB', 'activo' => true]);
        UnidadMedida::create(['nombre' => 'Litro', 'abreviatura' => 'L', 'activo' => true]);

        // Impuestos
        Impuesto::create(['nombre' => 'ITBIS 18%', 'tasa' => 18, 'activo' => true]);
        Impuesto::create(['nombre' => 'Exento 0%', 'tasa' => 0, 'activo' => true]);
    }
}
