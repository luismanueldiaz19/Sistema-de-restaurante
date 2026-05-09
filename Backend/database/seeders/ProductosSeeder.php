<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\Producto;

class ProductosSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        Producto::create([
            'nombre' => 'Hamburguesa Clásica',
            'codigo' => 'HAM-001',
            'descripcion' => 'Hamburguesa con queso y lechuga',
            'categoria' => 'COMIDA',
            'precio_venta' => 350,
            'costo' => 120,
            'itbis_porcentaje' => 18,
            'maneja_inventario' => true,
            'stock_actual' => 50,
            'stock_minimo' => 10,
            'cuenta_contable_ingresos' => '4.1.01',
            'cuenta_contable_inventario' => '1.1.05.01',
            'cuenta_contable_costos' => '5.1',
            'activo' => true,
        ]);

        Producto::create([
            'nombre' => 'Coca Cola 12oz',
            'codigo' => 'BEB-001',
            'descripcion' => 'Refresco de cola',
            'categoria' => 'BEBIDA',
            'precio_venta' => 75,
            'costo' => 30,
            'itbis_porcentaje' => 18,
            'maneja_inventario' => true,
            'stock_actual' => 100,
            'stock_minimo' => 24,
            'cuenta_contable_ingresos' => '4.1.02',
            'cuenta_contable_inventario' => '1.1.05.02',
            'cuenta_contable_costos' => '5.1',
            'activo' => true,
        ]);

        Producto::create([
            'nombre' => 'Servicio de Delivery',
            'codigo' => 'SERV-001',
            'descripcion' => 'Envío a domicilio',
            'categoria' => 'SERVICIOS',
            'precio_venta' => 100,
            'costo' => 0,
            'itbis_porcentaje' => 0,
            'maneja_inventario' => false,
            'stock_actual' => 0,
            'stock_minimo' => 0,
            'cuenta_contable_ingresos' => '4.1.01',
            'cuenta_contable_inventario' => '1.1.05.01',
            'cuenta_contable_costos' => '5.1',
            'activo' => true,
        ]);
    }
}
