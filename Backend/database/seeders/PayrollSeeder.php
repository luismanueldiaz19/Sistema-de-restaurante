<?php

namespace Database\Seeders;

use App\Models\Empleado;
use Illuminate\Database\Seeder;

class PayrollSeeder extends Seeder
{
    public function run(): void
    {
        Empleado::create([
            'nombre' => 'Juan Pérez',
            'cedula' => '001-1234567-1',
            'salario_base' => 45000.00,
            'fecha_ingreso' => '2023-01-15',
            'cargo' => 'Cajero Principal',
            'activo' => true
        ]);

        Empleado::create([
            'nombre' => 'Ana Martínez',
            'cedula' => '001-9876543-2',
            'salario_base' => 75000.00,
            'fecha_ingreso' => '2022-05-10',
            'cargo' => 'Administradora de Operaciones',
            'activo' => true
        ]);

        Empleado::create([
            'nombre' => 'Pedro Sánchez',
            'cedula' => '001-5555555-3',
            'salario_base' => 25000.00,
            'fecha_ingreso' => '2024-02-01',
            'cargo' => 'Auxiliar de Cocina',
            'activo' => true
        ]);
    }
}
