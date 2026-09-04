<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\Producto;
use App\Models\Categoria;
use App\Models\Impuesto;
use Illuminate\Support\Facades\DB;

class ProductosDominicanosSeeder extends Seeder
{
    /**
     * Run the database seeds.
     *
     * @return void
     */
    public function run()
    {
        $catComida = Categoria::where('nombre', 'Comida')->first();
        $catBebida = Categoria::where('nombre', 'Bebidas')->first();
        $imp18 = Impuesto::where('tasa', 18)->first();
        $imp0 = Impuesto::where('tasa', 0)->first();

        $this->command->info('Generando 10,000 productos dominicanos de prueba...');
        
        $faker = \Faker\Factory::create('es_ES'); 

        // Lista de algunos productos típicos dominicanos para usar como base
        $nombresBases = [
            'Plátano Verde', 'Plátano Maduro', 'Salami Super Especial', 'Queso de Freír', 
            'Queso en Hoja', 'Yuca', 'Mangú', 'Habichuelas Rojas', 'Habichuelas Negras', 
            'Habichuelas con Dulce', 'Pollo Horneado', 'Arroz Blanco', 'Concón', 
            'Mofongo de Chicharrón', 'Mofongo de Camarones', 'Sancocho de 7 Carnes', 
            'Pica Pollo', 'Chicharrón de Cerdo', 'Longaniza', 'Tostones', 
            'Batata Frita', 'Yaniqueque', 'Quipe', 'Empanada de Queso', 'Empanada de Pollo', 
            'Pastelón de Plátano Maduro', 'Morir Soñando', 'Café Santo Domingo', 
            'Cerveza Presidente', 'Refresco Kola Real', 'Refresco Country Club', 'Mamajuana',
            'Casabe', 'Dulce de Coco', 'Majarete'
        ];

        $productos = [];
        for ($i = 1; $i <= 10000; $i++) {
            $nombreBase = $faker->randomElement($nombresBases);
            $variante = $faker->word;
            
            // Randomizamos para que algunos tengan ITBIS (18%) y otros sean Exentos (0%)
            $esExento = $faker->boolean(40); // 40% de probabilidad de ser exento (ej. productos agrícolas/básicos)
            $impuestoId = $esExento ? ($imp0->id ?? null) : ($imp18->id ?? null);
            
            // Generamos costo y precio con un margen aleatorio
            $costo = $faker->randomFloat(2, 20, 1500);
            $precio = round($costo * $faker->randomFloat(2, 1.2, 2.5), 2); // Margen del 20% al 150%
            
            $isBebida = in_array($nombreBase, ['Morir Soñando', 'Café Santo Domingo', 'Cerveza Presidente', 'Refresco Kola Real', 'Refresco Country Club', 'Mamajuana']);
            $catId = $isBebida ? ($catBebida->id ?? null) : ($catComida->id ?? null);

            $productos[] = [
                'nombre' => $nombreBase . ' ' . ucfirst($variante) . ' ' . $i,
                'codigo' => 'PROD-DO-' . str_pad($i, 5, '0', STR_PAD_LEFT),
                'descripcion' => 'Producto dominicano generado automáticamente.',
                'categoria_id' => $catId,
                'tipo_producto' => 'PRODUCTO',
                'tipo_contable' => 'INVENTARIO',
                'precio_venta' => $precio,
                'costo' => $costo,
                'impuesto_id' => $impuestoId,
                'maneja_inventario' => $faker->boolean(85), // 85% maneja inventario
                'stock_minimo' => $faker->numberBetween(5, 100),
                'activo' => true,
                'created_at' => now(),
                'updated_at' => now(),
            ];

            // Insertar en bloques de 1000 para optimizar el rendimiento y no saturar la memoria
            if (count($productos) >= 1000) {
                DB::table('productos')->insert($productos);
                $productos = [];
            }
        }

        // Insertar los restantes si no fueron exactamente un múltiplo de 1000
        if (count($productos) > 0) {
            DB::table('productos')->insert($productos);
        }
        
        $this->command->info('Los 10,000 productos dominicanos se generaron exitosamente.');
    }
}
