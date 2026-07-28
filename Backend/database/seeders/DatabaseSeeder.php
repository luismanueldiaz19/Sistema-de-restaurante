<?php

namespace Database\Seeders;

// use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;

class DatabaseSeeder extends Seeder
{
    /**
     * Seed the application's database.
     */
    public function run()
    {
        $this->call([
            CatalogoCuentasSeeder::class,
            RolesAndPermissionsSeeder::class,
            NcfSecuenciaSeeder::class,
            UserSeeder::class,
            CajaAndTurnoSeeder::class,
            ClienteSeeder::class,
            CatalogosSeeder::class,
            ProductosSeeder::class,
            ConfiguracionContableSeeder::class,
            ProveedorSeeder::class,
        ]);
    }
}
