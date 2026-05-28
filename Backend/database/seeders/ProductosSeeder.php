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
            'nombre' => 'Hamburguesa Clásica',
            'codigo' => 'HAM-001',
            'descripcion' => 'Hamburguesa con queso y lechuga',
            'categoria_id' => $catComida->id ?? null,
            'tipo_producto' => 'PRODUCTO',
            'tipo_contable' => 'INVENTARIO',
            'precio_venta' => 350,
            'ultimo_costo' => 120,
            'costo_promedio' => 120,
            'impuesto_id' => $imp18->id ?? null,
            'maneja_inventario' => true,
            'stock_minimo' => 10,
            'activo' => true,
        ]);

        Producto::create([
            'nombre' => 'Coca Cola 12oz',
            'codigo' => 'BEB-001',
            'descripcion' => 'Refresco de cola',
            'categoria_id' => $catBebida->id ?? null,
            'tipo_producto' => 'PRODUCTO',
            'tipo_contable' => 'INVENTARIO',
            'precio_venta' => 75,
            'ultimo_costo' => 30,
            'costo_promedio' => 30,
            'impuesto_id' => $imp18->id ?? null,
            'maneja_inventario' => true,
            'stock_minimo' => 24,
            'activo' => true,
        ]);

        Producto::create([
            'nombre' => 'Servicio de Delivery',
            'codigo' => 'SERV-001',
            'descripcion' => 'Envío a domicilio',
            'categoria_id' => $catServicio->id ?? null,
            'tipo_producto' => 'SERVICIO',
            'tipo_contable' => 'SERVICIO',
            'precio_venta' => 100,
            'ultimo_costo' => 0,
            'costo_promedio' => 0,
            'impuesto_id' => $imp0->id ?? null,
            'maneja_inventario' => false,
            'stock_minimo' => 0,
            'activo' => true,
        ]);
    }
}
