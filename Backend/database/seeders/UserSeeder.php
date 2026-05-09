<?php

namespace Database\Seeders;

use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class UserSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run()
    {
        // Crear usuario administrador
        $admin = User::firstOrCreate(
            ['email' => 'lwader@gmail.com'],
            [
                'name'     => 'Administrador',
                'password' => Hash::make('199512'), // Cambiar en producción
            ]
        );

        // Asignar rol admin (que incluye todos los permisos)
        $admin->assignRole('admin');

        // Crear usuario cajero
        $cajero = User::firstOrCreate(
            ['email' => 'cajero@gmail.com'],
            [
                'name'     => 'Cajero de Prueba',
                'password' => Hash::make('cajero123'),
            ]
        );
        $cajero->assignRole('cajero');

        // Crear segundo usuario cajero
        $cajero2 = User::firstOrCreate(
            ['email' => 'cajero2@gmail.com'],
            [
                'name'     => 'Cajero Dos',
                'password' => Hash::make('cajero123'),
            ]
        );
        $cajero2->assignRole('cajero');
    }
}
