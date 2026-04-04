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
            [
                'tipo' => '31',
                'nombre' => 'Crédito Fiscal',
                'prefijo' => 'E',
                'actual' => 0,
                'created_at' => now(),
                'updated_at' => now(),
            ],
            [
                'tipo' => '32',
                'nombre' => 'Consumo',
                'prefijo' => 'E',
                'actual' => 0,
                'created_at' => now(),
                'updated_at' => now(),
            ],
            [
                'tipo' => '33',
                'nombre' => 'Nota de Débito',
                'prefijo' => 'E',
                'actual' => 0,
                'created_at' => now(),
                'updated_at' => now(),
            ],
        ]);
    }
}
