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
        $categorias = [
            ['nombre' => 'Comida', 'descripcion' => 'Alimentos preparados'],
            ['nombre' => 'Bebidas', 'descripcion' => 'Bebidas frías y calientes'],
            ['nombre' => 'Postres', 'descripcion' => 'Dulces y postres'],
            ['nombre' => 'Servicios', 'descripcion' => 'Servicios varios']
        ];
        foreach ($categorias as $c) {
            Categoria::firstOrCreate(['nombre' => $c['nombre']], ['descripcion' => $c['descripcion'], 'activo' => true]);
        }

        // Marcas
        $marcas = [
            ['nombre' => 'Generica', 'descripcion' => 'Marca genérica'],
            ['nombre' => 'Coca Cola', 'descripcion' => 'Refrescos']
        ];
        foreach ($marcas as $m) {
            Marca::firstOrCreate(['nombre' => $m['nombre']], ['descripcion' => $m['descripcion'], 'activo' => true]);
        }

        // Unidades de Medida
        $unidades = [
            ['nombre' => 'Unidad', 'abreviatura' => 'UND'],
            ['nombre' => 'Libra', 'abreviatura' => 'LB'],
            ['nombre' => 'Litro', 'abreviatura' => 'L'],
            ['nombre' => 'Kilogramo', 'abreviatura' => 'KG'],
            ['nombre' => 'Gramo', 'abreviatura' => 'G'],
            ['nombre' => 'Mililitro', 'abreviatura' => 'ML'],
            ['nombre' => 'Onza', 'abreviatura' => 'OZ'],
            ['nombre' => 'Galón', 'abreviatura' => 'GAL'],
            ['nombre' => 'Botella', 'abreviatura' => 'BOT'],
            ['nombre' => 'Porción', 'abreviatura' => 'POR'],
            ['nombre' => 'Paquete', 'abreviatura' => 'PAQ'],
            ['nombre' => 'Caja', 'abreviatura' => 'CAJ'],
            ['nombre' => 'Lata', 'abreviatura' => 'LAT'],
        ];

        foreach ($unidades as $u) {
            UnidadMedida::firstOrCreate(
                ['abreviatura' => $u['abreviatura']],
                ['nombre' => $u['nombre'], 'activo' => true]
            );
        }

        // Impuestos
        $impuestos = [
            ['nombre' => 'ITBIS 18%', 'tasa' => 18],
            ['nombre' => 'Exento 0%', 'tasa' => 0]
        ];
        foreach ($impuestos as $i) {
            Impuesto::firstOrCreate(['nombre' => $i['nombre']], ['tasa' => $i['tasa'], 'activo' => true]);
        }
    }
}
