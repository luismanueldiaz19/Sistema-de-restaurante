<?php

namespace Database\Seeders;

use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

class NcfSecuenciaSeeder extends Seeder
{
    /**
     * Run the database seeds.
     *
     * @return void
     */
     public function run(): void
    {
        DB::table('ncf_secuencias')->insert([
            ['tipo' => '31', 'nombre' => 'Factura de Crédito Fiscal Electrónica', 'prefijo' => 'E', 'actual' => 0, 'created_at' => now(), 'updated_at' => now()],
            ['tipo' => '32', 'nombre' => 'Factura de Consumo Electrónica', 'prefijo' => 'E', 'actual' => 0, 'created_at' => now(), 'updated_at' => now()],
            ['tipo' => '33', 'nombre' => 'Nota de Débito Electrónica', 'prefijo' => 'E', 'actual' => 0, 'created_at' => now(), 'updated_at' => now()],
            ['tipo' => '34', 'nombre' => 'Nota de Crédito Electrónica', 'prefijo' => 'E', 'actual' => 0, 'created_at' => now(), 'updated_at' => now()],
            ['tipo' => '41', 'nombre' => 'Comprobante Electrónico de Compras', 'prefijo' => 'E', 'actual' => 0, 'created_at' => now(), 'updated_at' => now()],
            ['tipo' => '43', 'nombre' => 'Comprobante Electrónico para Gastos Menores', 'prefijo' => 'E', 'actual' => 0, 'created_at' => now(), 'updated_at' => now()],
            ['tipo' => '44', 'nombre' => 'Comprobante Electrónico para Regímenes Especiales', 'prefijo' => 'E', 'actual' => 0, 'created_at' => now(), 'updated_at' => now()],
            ['tipo' => '45', 'nombre' => 'Comprobante Electrónico Gubernamental', 'prefijo' => 'E', 'actual' => 0, 'created_at' => now(), 'updated_at' => now()],
            ['tipo' => '46', 'nombre' => 'Comprobante Electrónico para Exportaciones', 'prefijo' => 'E', 'actual' => 0, 'created_at' => now(), 'updated_at' => now()],
            ['tipo' => '47', 'nombre' => 'Comprobante Electrónico para Pagos al Exterior', 'prefijo' => 'E', 'actual' => 0, 'created_at' => now(), 'updated_at' => now()],
        ]);
    }
}
