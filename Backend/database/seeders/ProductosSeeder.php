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
            'ultimo_costo' => 16.66,
            'costo_promedio' => 16.66,
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
            'tipo_producto' => 'PRODUCTO',
            'tipo_contable' => 'INVENTARIO',
            'precio_venta' => 250.00,
            'ultimo_costo' => 117.50,
            'costo_promedio' => 117.50,
            'impuesto_id' => $imp18->id ?? null,
            'maneja_inventario' => true,
            'stock_minimo' => 10,
            'activo' => true,
        ]);

        /*
        |--------------------------------------------------------------------------
        | MATERIAS PRIMAS
        |--------------------------------------------------------------------------
        */

        // Producto::create([
        //     'nombre' => 'Pan para Hamburguesa',
        //     'codigo' => 'MP-001',
        //     'descripcion' => 'Pan brioche para hamburguesa.',
        //     'categoria_id' => $catMateriaPrima->id ?? null,
        //     'tipo_producto' => 'MATERIA_PRIMA',
        //     'tipo_contable' => 'INVENTARIO',
        //     'precio_venta' => 0,
        //     'ultimo_costo' => 12.00,
        //     'costo_promedio' => 12.00,
        //     'impuesto_id' => $imp18->id ?? null,
        //     'maneja_inventario' => true,
        //     'stock_minimo' => 50,
        //     'activo' => true,
        // ]);

        // Producto::create([
        //     'nombre' => 'Carne de Res para Hamburguesa',
        //     'codigo' => 'MP-002',
        //     'descripcion' => 'Carne molida preparada.',
        //     'categoria_id' => $catMateriaPrima->id ?? null,
        //     'tipo_producto' => 'MATERIA_PRIMA',
        //     'tipo_contable' => 'INVENTARIO',
        //     'precio_venta' => 0,
        //     'ultimo_costo' => 400.00,
        //     'costo_promedio' => 400.00,
        //     'impuesto_id' => $imp18->id ?? null,
        //     'maneja_inventario' => true,
        //     'stock_minimo' => 5,
        //     'activo' => true,
        // ]);

        // Producto::create([
        //     'nombre' => 'Queso Cheddar',
        //     'codigo' => 'MP-003',
        //     'descripcion' => 'Queso cheddar en lonchas.',
        //     'categoria_id' => $catMateriaPrima->id ?? null,
        //     'tipo_producto' => 'MATERIA_PRIMA',
        //     'tipo_contable' => 'INVENTARIO',
        //     'precio_venta' => 0,
        //     'ultimo_costo' => 240.00,
        //     'costo_promedio' => 240.00,
        //     'impuesto_id' => $imp18->id ?? null,
        //     'maneja_inventario' => true,
        //     'stock_minimo' => 3,
        //     'activo' => true,
        // ]);

        // Producto::create([
        //     'nombre' => 'Lechuga',
        //     'codigo' => 'MP-004',
        //     'descripcion' => 'Lechuga fresca.',
        //     'categoria_id' => $catMateriaPrima->id ?? null,
        //     'tipo_producto' => 'MATERIA_PRIMA',
        //     'tipo_contable' => 'INVENTARIO',
        //     'precio_venta' => 0,
        //     'ultimo_costo' => 80.00,
        //     'costo_promedio' => 80.00,
        //     'impuesto_id' => $imp18->id ?? null,
        //     'maneja_inventario' => true,
        //     'stock_minimo' => 2,
        //     'activo' => true,
        // ]);

        // Producto::create([
        //     'nombre' => 'Tomate',
        //     'codigo' => 'MP-005',
        //     'descripcion' => 'Tomate fresco.',
        //     'categoria_id' => $catMateriaPrima->id ?? null,
        //     'tipo_producto' => 'MATERIA_PRIMA',
        //     'tipo_contable' => 'INVENTARIO',
        //     'precio_venta' => 0,
        //     'ultimo_costo' => 70.00,
        //     'costo_promedio' => 70.00,
        //     'impuesto_id' => $imp18->id ?? null,
        //     'maneja_inventario' => true,
        //     'stock_minimo' => 2,
        //     'activo' => true,
        // ]);

        // Producto::create([
        //     'nombre' => 'Cebolla',
        //     'codigo' => 'MP-006',
        //     'descripcion' => 'Cebolla blanca.',
        //     'categoria_id' => $catMateriaPrima->id ?? null,
        //     'tipo_producto' => 'MATERIA_PRIMA',
        //     'tipo_contable' => 'INVENTARIO',
        //     'precio_venta' => 0,
        //     'ultimo_costo' => 60.00,
        //     'costo_promedio' => 60.00,
        //     'impuesto_id' => $imp18->id ?? null,
        //     'maneja_inventario' => true,
        //     'stock_minimo' => 2,
        //     'activo' => true,
        // ]);

        // Producto::create([
        //     'nombre' => 'Pepinillos',
        //     'codigo' => 'MP-007',
        //     'descripcion' => 'Pepinillos en conserva.',
        //     'categoria_id' => $catMateriaPrima->id ?? null,
        //     'tipo_producto' => 'MATERIA_PRIMA',
        //     'tipo_contable' => 'INVENTARIO',
        //     'precio_venta' => 0,
        //     'ultimo_costo' => 180.00,
        //     'costo_promedio' => 180.00,
        //     'impuesto_id' => $imp18->id ?? null,
        //     'maneja_inventario' => true,
        //     'stock_minimo' => 2,
        //     'activo' => true,
        // ]);

        // Producto::create([
        //     'nombre' => 'Ketchup',
        //     'codigo' => 'MP-008',
        //     'descripcion' => 'Salsa de tomate.',
        //     'categoria_id' => $catMateriaPrima->id ?? null,
        //     'tipo_producto' => 'MATERIA_PRIMA',
        //     'tipo_contable' => 'INVENTARIO',
        //     'precio_venta' => 0,
        //     'ultimo_costo' => 150.00,
        //     'costo_promedio' => 150.00,
        //     'impuesto_id' => $imp18->id ?? null,
        //     'maneja_inventario' => true,
        //     'stock_minimo' => 2,
        //     'activo' => true,
        // ]);

        // Producto::create([
        //     'nombre' => 'Mayonesa',
        //     'codigo' => 'MP-009',
        //     'descripcion' => 'Mayonesa.',
        //     'categoria_id' => $catMateriaPrima->id ?? null,
        //     'tipo_producto' => 'MATERIA_PRIMA',
        //     'tipo_contable' => 'INVENTARIO',
        //     'precio_venta' => 0,
        //     'ultimo_costo' => 170.00,
        //     'costo_promedio' => 170.00,
        //     'impuesto_id' => $imp18->id ?? null,
        //     'maneja_inventario' => true,
        //     'stock_minimo' => 2,
        //     'activo' => true,
        // ]);

        // Producto::create([
        //     'nombre' => 'Mostaza',
        //     'codigo' => 'MP-010',
        //     'descripcion' => 'Mostaza amarilla.',
        //     'categoria_id' => $catMateriaPrima->id ?? null,
        //     'tipo_producto' => 'MATERIA_PRIMA',
        //     'tipo_contable' => 'INVENTARIO',
        //     'precio_venta' => 0,
        //     'ultimo_costo' => 140.00,
        //     'costo_promedio' => 140.00,
        //     'impuesto_id' => $imp18->id ?? null,
        //     'maneja_inventario' => true,
        //     'stock_minimo' => 2,
        //     'activo' => true,
        // ]);


        // Producto::create([
        //     'nombre' => 'Hamburguesa Clásica',
        //     'codigo' => 'HAM-001',
        //     'descripcion' => 'Hamburguesa con queso y lechuga',
        //     'categoria_id' => $catComida->id ?? null,
        //     'tipo_producto' => 'PRODUCTO',
        //     'tipo_contable' => 'INVENTARIO',
        //     'precio_venta' => 350,
        //     'ultimo_costo' => 120,
        //     'costo_promedio' => 120,
        //     'impuesto_id' => $imp18->id ?? null,
        //     'maneja_inventario' => true,
        //     'stock_minimo' => 10,
        //     'activo' => true,
        // ]);

        // Producto::create([
        //     'nombre' => 'Tomates Frescos (Libras)',
        //     'codigo' => 'MAT-001',
        //     'descripcion' => 'Tomates frescos para ensaladas y salsas',
        //     'categoria_id' => $catComida->id ?? null,
        //     'tipo_producto' => 'MATERIA_PRIMA',
        //     'tipo_contable' => 'INVENTARIO',
        //     'precio_venta' => 0, // No se vende directo
        //     'ultimo_costo' => 45.50,
        //     'costo_promedio' => 45.50,
        //     'impuesto_id' => $imp0->id ?? null, // Exento
        //     'maneja_inventario' => true,
        //     'stock_minimo' => 20,
        //     'activo' => true,
        // ]);

        // Producto::create([
        //     'nombre' => 'Pechuga de Pollo (Libras)',
        //     'codigo' => 'MAT-002',
        //     'descripcion' => 'Pechuga de pollo deshuesada',
        //     'categoria_id' => $catComida->id ?? null,
        //     'tipo_producto' => 'MATERIA_PRIMA',
        //     'tipo_contable' => 'INVENTARIO',
        //     'precio_venta' => 0,
        //     'ultimo_costo' => 110.00,
        //     'costo_promedio' => 110.00,
        //     'impuesto_id' => $imp0->id ?? null, // Exento
        //     'maneja_inventario' => true,
        //     'stock_minimo' => 50,
        //     'activo' => true,
        // ]);

        // Producto::create([
        //     'nombre' => 'Coca Cola 12oz',
        //     'codigo' => 'BEB-001',
        //     'descripcion' => 'Refresco de cola',
        //     'categoria_id' => $catBebida->id ?? null,
        //     'tipo_producto' => 'PRODUCTO',
        //     'tipo_contable' => 'INVENTARIO',
        //     'precio_venta' => 75,
        //     'ultimo_costo' => 30,
        //     'costo_promedio' => 30,
        //     'impuesto_id' => $imp18->id ?? null,
        //     'maneja_inventario' => true,
        //     'stock_minimo' => 24,
        //     'activo' => true,
        // ]);

        // Producto::create([
        //     'nombre' => 'Servicio de Delivery',
        //     'codigo' => 'SERV-001',
        //     'descripcion' => 'Envío a domicilio',
        //     'categoria_id' => $catServicio->id ?? null,
        //     'tipo_producto' => 'SERVICIO',
        //     'tipo_contable' => 'SERVICIO',
        //     'precio_venta' => 100,
        //     'ultimo_costo' => 0,
        //     'costo_promedio' => 0,
        //     'impuesto_id' => $imp0->id ?? null,
        //     'maneja_inventario' => false,
        //     'stock_minimo' => 0,
        //     'activo' => true,
        // ]);
    }
}
