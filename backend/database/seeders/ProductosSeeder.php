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

        // Producto 1: Bebida
        Producto::create([
            'nombre' => 'Kola Real',
            'codigo' => 'KR-2516',
            'descripcion' => 'Refresco',
            'categoria_id' => $catBebida->id ?? null,
            'marca_id' => null,
            'unidad_medida_id' => null,
            'tipo_producto' => 'PRODUCTO',
            'tipo_contable' => 'INVENTARIO',
            'maneja_inventario' => true,
            'maneja_vencimiento' => true,
            'stock_actual' => 1500,
            'stock_minimo' => 100,
            'presentacion_compra_por_defecto' => 'Caja de 12',
            'factor_compra_por_defecto' => 12.00,
            'precio_venta' => 25.00,
            'precio_compra' => 230,
            'costo' => 16.2429,
            'impuesto_id' => $imp18->id ?? null,
            'impuesto_venta_id' => $imp18->id ?? null,
            'impuesto_compra_id' => $imp18->id ?? null,
            'cuenta_ingreso_id' => null,
            'cuenta_inventario_id' => null,
            'cuenta_costo_id' => null,
            'cuenta_gasto_id' => null,
            'activo' => true,
            'created_by' => 1,
        ]);

        // Producto 2: Hamburguesa
        Producto::create([
            'nombre' => 'Hamburguesa Clásica',
            'codigo' => 'HB-001',
            'descripcion' => 'Hamburguesa de res con queso y vegetales.',
            'categoria_id' => $catComida->id ?? null,
            'marca_id' => null,
            'unidad_medida_id' => null,
            'tipo_producto' => 'COMBO',
            'tipo_contable' => 'INVENTARIO',
            'maneja_inventario' => false,
            'maneja_vencimiento' => false,
            'stock_actual' => 0,
            'stock_minimo' => 10,
            'presentacion_compra_por_defecto' => null,
            'factor_compra_por_defecto' => null,
            'precio_venta' => 250.00,
            'precio_compra' => 0,
            'costo' => 117.50,
            'impuesto_id' => $imp18->id ?? null,
            'impuesto_venta_id' => $imp18->id ?? null,
            'impuesto_compra_id' => null,
            'cuenta_ingreso_id' => null,
            'cuenta_inventario_id' => null,
            'cuenta_costo_id' => null,
            'cuenta_gasto_id' => null,
            'activo' => true,
            'created_by' => 1,
        ]);

        // Producto 3: Plato del dia
        Producto::create([
            'nombre' => 'Plato del dia 250',
            'codigo' => 'PD-250',
            'descripcion' => 'Plato del dia',
            'categoria_id' => $catComida->id ?? null,
            'marca_id' => null,
            'unidad_medida_id' => null,
            'tipo_producto' => 'PLATO',
            'tipo_contable' => 'INVENTARIO',
            'maneja_inventario' => false,
            'maneja_vencimiento' => false,
            'stock_actual' => 0,
            'stock_minimo' => 0,
            'presentacion_compra_por_defecto' => null,
            'factor_compra_por_defecto' => null,
            'precio_venta' => 250.00,
            'precio_compra' => 0,
            'costo' => 150.00,
            'impuesto_id' => $imp18->id ?? null,
            'impuesto_venta_id' => $imp18->id ?? null,
            'impuesto_compra_id' => null,
            'cuenta_ingreso_id' => null,
            'cuenta_inventario_id' => null,
            'cuenta_costo_id' => null,
            'cuenta_gasto_id' => null,
            'activo' => true,
            'created_by' => 1,
        ]);

        // Producto 4: Lasagna
        Producto::create([
            'nombre' => 'Lasagna',
            'codigo' => 'LAS-001',
            'descripcion' => 'Lasagna',
            'categoria_id' => $catComida->id ?? null,
            'marca_id' => null,
            'unidad_medida_id' => null,
            'tipo_producto' => 'PLATO',
            'tipo_contable' => 'INVENTARIO',
            'maneja_inventario' => false,
            'maneja_vencimiento' => false,
            'stock_actual' => 0,
            'stock_minimo' => 0,
            'presentacion_compra_por_defecto' => null,
            'factor_compra_por_defecto' => null,
            'precio_venta' => 300.00,
            'precio_compra' => 0,
            'costo' => 180.00,
            'impuesto_id' => $imp18->id ?? null,
            'impuesto_venta_id' => $imp18->id ?? null,
            'impuesto_compra_id' => null,
            'cuenta_ingreso_id' => null,
            'cuenta_inventario_id' => null,
            'cuenta_costo_id' => null,
            'cuenta_gasto_id' => null,
            'activo' => true,
            'created_by' => 1,
        ]);

        // Producto 5: Servicio
        Producto::create([
            'nombre' => 'Servicios Delivery',
            'codigo' => 'SERV-DEL',
            'descripcion' => 'Servicios de Delivery',
            'categoria_id' => $catServicio->id ?? null,
            'marca_id' => null,
            'unidad_medida_id' => null,
            'tipo_producto' => 'SERVICIO',
            'tipo_contable' => 'SERVICIO',
            'maneja_inventario' => false,
            'maneja_vencimiento' => false,
            'stock_actual' => 0,
            'stock_minimo' => 0,
            'presentacion_compra_por_defecto' => null,
            'factor_compra_por_defecto' => null,
            'precio_venta' => 20.00,
            'precio_compra' => 0,
            'costo' => 16.66,
            'impuesto_id' => $imp0->id ?? null,
            'impuesto_venta_id' => $imp0->id ?? null,
            'impuesto_compra_id' => null,
            'cuenta_ingreso_id' => null,
            'cuenta_inventario_id' => null,
            'cuenta_costo_id' => null,
            'cuenta_gasto_id' => null,
            'activo' => true,
            'created_by' => 1,
        ]);
    }
}
