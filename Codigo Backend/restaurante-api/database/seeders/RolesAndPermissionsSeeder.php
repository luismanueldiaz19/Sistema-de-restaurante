<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Spatie\Permission\Models\Permission;
use Spatie\Permission\Models\Role;

class RolesAndPermissionsSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run()
    {
        // 🔐 PERMISOS
        $permisos = [

            // CLIENTES
            'ver_clientes',
            'crear_clientes',
            'editar_clientes',
            'eliminar_clientes',

            // FACTURAS
            'ver_facturas',
            'crear_facturas',
            'editar_facturas',
            'eliminar_facturas',

            // EVENTOS / BUFFET
            'ver_eventos',
            'crear_eventos',

            // GASTOS
            'ver_gastos',
            'crear_gastos',

            // NOMINA
            'ver_nomina',

            // USUARIOS
            'gestionar_usuarios'
        ];

        foreach ($permisos as $permiso) {
            Permission::firstOrCreate(['name' => $permiso]);
        }

        // 👑 ADMIN
        $admin = Role::firstOrCreate(['name' => 'admin']);
        $admin->givePermissionTo(Permission::all());

        // 🧑‍💼 VENDEDOR
        $vendedor = Role::firstOrCreate(['name' => 'vendedor']);
        $vendedor->givePermissionTo([
            'ver_clientes',
            'crear_clientes',
            'ver_facturas',
            'crear_facturas',
            'ver_eventos',
            'crear_eventos'
        ]);

    }
}
