<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\ConfiguracionContable;
use App\Models\CatalogoCuenta;

class ConfiguracionContableSeeder extends Seeder
{
    /**
     * Run the database seeds.
     *
     * @return void
     */
    public function run()
    {
        $configs = [
            // Ventas
            [
                'clave' => 'venta_efectivo_debe',
                'nombre' => 'Cobro de Ventas en Efectivo (Débito)',
                'grupo' => 'Ventas',
                'codigo_cuenta' => '1.1.01.01', // CAJA GENERAL
            ],
            [
                'clave' => 'venta_credito_debe',
                'nombre' => 'Cobro de Ventas a Crédito (Débito)',
                'grupo' => 'Ventas',
                'codigo_cuenta' => '1.1.03', // CUENTAS POR COBRAR CLIENTES
            ],
            [
                'clave' => 'venta_haber',
                'nombre' => 'Ingresos por Ventas de Comida (Crédito)',
                'grupo' => 'Ventas',
                'codigo_cuenta' => '4.1.01', // VENTAS DE ALIMENTOS
            ],
            [
                'clave' => 'venta_itbis_haber',
                'nombre' => 'ITBIS Recaudado por Ventas (Crédito)',
                'grupo' => 'Ventas',
                'codigo_cuenta' => '2.1.02', // ITBIS POR PAGAR
            ],

            [
                'clave' => 'venta_costo_debe',
                'nombre' => 'Costo de Ventas (Débito)',
                'grupo' => 'Ventas',
                'codigo_cuenta' => '5.1', // COSTO DE VENTAS O COSTO DE MERCANCIA
            ],
            [
                'clave' => 'venta_inventario_haber',
                'nombre' => 'Salida de Inventario por Venta (Crédito)',
                'grupo' => 'Ventas',
                'codigo_cuenta' => '1.1.05.01', // INVENTARIO DE ALIMENTOS
            ],

            // Compras
            [
                'clave' => 'compra_inventario_debe',
                'nombre' => 'Adquisición de Mercancía / Inventario (Débito)',
                'grupo' => 'Compras',
                'codigo_cuenta' => '1.1.05.01', // INVENTARIO DE ALIMENTOS
            ],
            [
                'clave' => 'compra_proveedor_haber',
                'nombre' => 'Obligaciones con Proveedores (Crédito)',
                'grupo' => 'Compras',
                'codigo_cuenta' => '2.1.01', // CUENTAS POR PAGAR PROVEEDORES
            ],
            [
                'clave' => 'compra_itbis_debe',
                'nombre' => 'ITBIS Adelantado en Compras (Débito)',
                'grupo' => 'Compras',
                'codigo_cuenta' => '2.1.02', // ITBIS POR PAGAR
            ],
            [
                'clave' => 'itbis_retenido_por_pagar',
                'nombre' => 'ITBIS Retenido por Pagar (Crédito - Proveedores Informales)',
                'grupo' => 'Compras',
                'codigo_cuenta' => '2.1.03', // ITBIS RETENIDO POR PAGAR
            ],
            [
                'clave' => 'pago_compra_efectivo_haber',
                'nombre' => 'Pago a Proveedor en Efectivo/Banco (Crédito)',
                'grupo' => 'Compras',
                'codigo_cuenta' => '1.1.01.01', // CAJA GENERAL
            ],

            // Nómina
            [
                'clave' => 'nomina_gasto_debe',
                'nombre' => 'Gasto de Sueldos y Nómina (Débito)',
                'grupo' => 'Nomina',
                'codigo_cuenta' => '6.1', // NOMINA Y SALARIOS
            ],
            [
                'clave' => 'nomina_pago_haber',
                'nombre' => 'Banco de Desembolso de Nómina (Crédito)',
                'grupo' => 'Nomina',
                'codigo_cuenta' => '1.1.01.03', // BANCO OPERATIVO
            ],

            // Impuestos / DGII
            [
                'clave' => 'pago_dgii_itbis_debe',
                'nombre' => 'Pago a la DGII (ITBIS por Pagar - Débito)',
                'grupo' => 'Impuestos',
                'codigo_cuenta' => '2.1.02', // ITBIS POR PAGAR
            ],
        ];

        foreach ($configs as $configData) {
            $cuenta = CatalogoCuenta::where('codigo', $configData['codigo_cuenta'])->first();
            
            ConfiguracionContable::updateOrCreate(
                ['clave' => $configData['clave']],
                [
                    'nombre' => $configData['nombre'],
                    'grupo' => $configData['grupo'],
                    'cuenta_id' => $cuenta ? $cuenta->id : null,
                ]
            );
        }
    }
}
