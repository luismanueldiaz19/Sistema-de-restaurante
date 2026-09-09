<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\Producto;
use App\Models\Categoria;
use App\Models\Impuesto;

class ProductosSeeder extends Seeder
{
    public function run(): void
    {
        $catComida = Categoria::where('nombre', 'Comida')->first();
        $catBebida = Categoria::where('nombre', 'Bebidas')->first();
        $catServicio = Categoria::where('nombre', 'Servicios')->first();
        $imp18 = Impuesto::where('tasa', 18)->first();
        $imp0 = Impuesto::where('tasa', 0)->first();

        Producto::create([
            'nombre' => 'Kola Real',
            'codigo' => 'KR-2516',
            'descripcion' => 'Refresco',
            'categoria_id' => $catBebida->id ?? null,
            'tipo_producto' => 'PRODUCTO',
            'tipo_contable' => 'INVENTARIO',
            'precio_venta' => 25.00,
            'costo' => 16.66,
            'impuesto_id' => $imp18->id ?? null,
            'maneja_inventario' => true,
            'stock_minimo' => 50,
            'activo' => true,
        ]);

           Producto::create([
            'nombre' => 'Hamburguesa Clásica',
            'codigo' => 'HB-001',
            'descripcion' => 'Hamburguesa de res con queso y vegetales.',
            'categoria_id' => $catComida->id ?? null,
            'tipo_producto' => 'COMBO',
            'tipo_contable' => 'INVENTARIO',
            'precio_venta' => 250.00,
            'costo' => 117.50,
            'impuesto_id' => $imp18->id ?? null,
            'maneja_inventario' => false,
            'stock_minimo' => 10,
            'activo' => true,
        ]);

            Producto::create([
            'nombre' => 'Plata del dia 250',
            'codigo' => 'PD-250',
            'descripcion' => 'Plata del dia',
            'categoria_id' => $catComida->id ?? null,
            'tipo_producto' => 'COMBO',
            'tipo_contable' => 'INVENTARIO',
            'precio_venta' => 250.00,
            'costo' => 150.00,
            'impuesto_id' => $imp18->id ?? null,
            'maneja_inventario' => false,
            'stock_minimo' => 0,
            'activo' => true,
        ]);


            Producto::create([
            'nombre' => 'Lasagna',
            'codigo' => 'LAS-001',
            'descripcion' => 'Lasagna',
            'categoria_id' => $catComida->id ?? null,
            'tipo_producto' => 'COMBO',
            'tipo_contable' => 'INVENTARIO',
            'precio_venta' => 300.00,
            'costo' => 180.00,
            'impuesto_id' => $imp18->id ?? null,
            'maneja_inventario' => false,
            'stock_minimo' => 0,
            'activo' => true,
        ]);

          Producto::create([
            'nombre' => 'Servicios Delivery',
            'codigo' => 'SERV-DEL',
            'descripcion' => 'Servicios de Delivery',
            'categoria_id' => $catServicio->id ?? null,
            'tipo_producto' => 'SERVICIO',
            'tipo_contable' => 'SERVICIO',
            'precio_venta' => 20.00,
            'costo' => 16.66,
            'impuesto_id' => $imp0->id ?? null,
            'maneja_inventario' => false,
            'stock_minimo' => 0,
            'activo' => true,
        ]);


    }
}
