<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\CatalogoCuenta;

class CatalogoCuentasSeeder extends Seeder
{
    public function run()
    {
        // --- 1. ACTIVOS ---
        $activos = CatalogoCuenta::create([
            'codigo' => '1',
            'nombre' => 'ACTIVOS',
            'tipo'   => 'Activo',
            'nivel'  => 1,
            'permite_movimiento' => false
        ]);

        $corrientes = CatalogoCuenta::create([
            'codigo' => '1.1',
            'nombre' => 'ACTIVOS CORRIENTES',
            'tipo'   => 'Activo',
            'nivel'  => 2,
            'padre_id' => $activos->id,
            'permite_movimiento' => false
        ]);

        // Efectivo
        $efectivo = CatalogoCuenta::create([
            'codigo' => '1.1.01',
            'nombre' => 'EFECTIVO EN CAJA Y BANCOS',
            'tipo'   => 'Activo',
            'nivel'  => 3,
            'padre_id' => $corrientes->id,
            'permite_movimiento' => false
        ]);

        CatalogoCuenta::create([
            'codigo' => '1.1.01.01',
            'nombre' => 'CAJA GENERAL',
            'tipo'   => 'Activo',
            'nivel'  => 4,
            'padre_id' => $efectivo->id,
            'permite_movimiento' => true
        ]);

        CatalogoCuenta::create([
            'codigo' => '1.1.01.02',
            'nombre' => 'CAJA CHICA RESTAURANTE',
            'tipo'   => 'Activo',
            'nivel'  => 4,
            'padre_id' => $efectivo->id,
            'permite_movimiento' => true
        ]);

        CatalogoCuenta::create([
            'codigo' => '1.1.01.03',
            'nombre' => 'BANCO OPERATIVO',
            'tipo'   => 'Activo',
            'nivel'  => 4,
            'padre_id' => $efectivo->id,
            'permite_movimiento' => true
        ]);

        // Cuentas por Cobrar
        $cxc = CatalogoCuenta::create([
            'codigo' => '1.1.03',
            'nombre' => 'CUENTAS POR COBRAR CLIENTES',
            'tipo'   => 'Activo',
            'nivel'  => 3,
            'padre_id' => $corrientes->id,
            'permite_movimiento' => true
        ]);

        // Inventarios
        $inventarios = CatalogoCuenta::create([
            'codigo' => '1.1.05',
            'nombre' => 'INVENTARIOS',
            'tipo'   => 'Activo',
            'nivel'  => 3,
            'padre_id' => $corrientes->id,
            'permite_movimiento' => false
        ]);

        CatalogoCuenta::create([
            'codigo' => '1.1.05.01',
            'nombre' => 'INVENTARIO DE ALIMENTOS',
            'tipo'   => 'Activo',
            'nivel'  => 4,
            'padre_id' => $inventarios->id,
            'permite_movimiento' => true
        ]);

        CatalogoCuenta::create([
            'codigo' => '1.1.05.02',
            'nombre' => 'INVENTARIO DE BEBIDAS',
            'tipo'   => 'Activo',
            'nivel'  => 4,
            'padre_id' => $inventarios->id,
            'permite_movimiento' => true
        ]);

        // --- 2. PASIVOS ---
        $pasivos = CatalogoCuenta::create([
            'codigo' => '2',
            'nombre' => 'PASIVOS',
            'tipo'   => 'Pasivo',
            'nivel'  => 1,
            'permite_movimiento' => false
        ]);

        $pasCorrientes = CatalogoCuenta::create([
            'codigo' => '2.1',
            'nombre' => 'PASIVOS CORRIENTES',
            'tipo'   => 'Pasivo',
            'nivel'  => 2,
            'padre_id' => $pasivos->id,
            'permite_movimiento' => false
        ]);

        CatalogoCuenta::create([
            'codigo' => '2.1.01',
            'nombre' => 'CUENTAS POR PAGAR PROVEEDORES',
            'tipo'   => 'Pasivo',
            'nivel'  => 3,
            'padre_id' => $pasCorrientes->id,
            'permite_movimiento' => true
        ]);

        CatalogoCuenta::create([
            'codigo' => '2.1.02',
            'nombre' => 'ITBIS POR PAGAR',
            'tipo'   => 'Pasivo',
            'nivel'  => 3,
            'padre_id' => $pasCorrientes->id,
            'permite_movimiento' => true
        ]);

        CatalogoCuenta::create([
            'codigo' => '2.1.03',
            'nombre' => 'ITBIS RETENIDO POR PAGAR',
            'tipo'   => 'Pasivo',
            'nivel'  => 3,
            'padre_id' => $pasCorrientes->id,
            'permite_movimiento' => true
        ]);

        // --- 3. CAPITAL ---
        $capital = CatalogoCuenta::create([
            'codigo' => '3',
            'nombre' => 'CAPITAL Y RESERVAS',
            'tipo'   => 'Capital',
            'nivel'  => 1,
            'permite_movimiento' => false
        ]);

        // --- 4. INGRESOS ---
        $ingresos = CatalogoCuenta::create([
            'codigo' => '4',
            'nombre' => 'INGRESOS',
            'tipo'   => 'Ingresos',
            'nivel'  => 1,
            'permite_movimiento' => false
        ]);

        $ventas = CatalogoCuenta::create([
            'codigo' => '4.1',
            'nombre' => 'VENTAS OPERATIVAS',
            'tipo'   => 'Ingresos',
            'nivel'  => 2,
            'padre_id' => $ingresos->id,
            'permite_movimiento' => false
        ]);

        CatalogoCuenta::create([
            'codigo' => '4.1.01',
            'nombre' => 'VENTAS DE ALIMENTOS',
            'tipo'   => 'Ingresos',
            'nivel'  => 3,
            'padre_id' => $ventas->id,
            'permite_movimiento' => true
        ]);

        CatalogoCuenta::create([
            'codigo' => '4.1.02',
            'nombre' => 'VENTAS DE BEBIDAS',
            'tipo'   => 'Ingresos',
            'nivel'  => 3,
            'padre_id' => $ventas->id,
            'permite_movimiento' => true
        ]);

        // --- 5. COSTOS ---
        $costos = CatalogoCuenta::create([
            'codigo' => '5',
            'nombre' => 'COSTOS DE VENTAS',
            'tipo'   => 'Costos',
            'nivel'  => 1,
            'permite_movimiento' => false
        ]);

        CatalogoCuenta::create([
            'codigo' => '5.1',
            'nombre' => 'COSTO DE ALIMENTOS',
            'tipo'   => 'Costos',
            'nivel'  => 2,
            'padre_id' => $costos->id,
            'permite_movimiento' => true
        ]);

        // --- 6. GASTOS ---
        $gastos = CatalogoCuenta::create([
            'codigo' => '6',
            'nombre' => 'GASTOS OPERATIVOS',
            'tipo'   => 'Gastos',
            'nivel'  => 1,
            'permite_movimiento' => false
        ]);

        CatalogoCuenta::create([
            'codigo' => '6.1',
            'nombre' => 'NOMINA Y SALARIOS',
            'tipo'   => 'Gastos',
            'nivel'  => 2,
            'padre_id' => $gastos->id,
            'permite_movimiento' => true
        ]);
    }
}
