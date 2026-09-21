<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\Cliente;

class ClienteSeeder extends Seeder
{
    /**
     * Run the database seeds.
     *
     * @return void
     */
    public function run()
    {
        Cliente::create([
            'nombre' => 'Generico',
            'rnc_cedula' => '000-0000000-0',
            'tipo_cliente' => 'consumidor_final',
            'cuenta_contable' => '1.1.03.01',
            'limite_credito' => 0,
            'saldo_actual' => 0,
            'activo' => true,
        ]);

        // Cliente::create([
        //     'nombre' => 'Juan Pérez (Crédito)',
        //     'rnc_cedula' => '001-1234567-8',
        //     'email' => 'juan@example.com',
        //     'telefono' => '809-555-1234',
        //     'tipo_cliente' => 'credito',
        //     'cuenta_contable' => '1.1.03.02',
        //     'limite_credito' => 50000,
        //     'saldo_actual' => 1500,
        //     'dias_credito' => 30,
        //     'activo' => true,
        // ]);

        // Cliente::create([
        //     'nombre' => 'Constructora Nacional',
        //     'rnc_cedula' => '1-31-01234-5',
        //     'email' => 'ventas@constructora.com',
        //     'tipo_cliente' => 'gubernamental',
        //     'cuenta_contable' => '1.1.03.03',
        //     'limite_credito' => 500000,
        //     'saldo_actual' => 0,
        //     'dias_credito' => 60,
        //     'activo' => true,
        // ]);

        // $this->command->info('Generando 10,000 clientes de prueba...');
        
        // $faker = \Faker\Factory::create();
        // $tipos = ['consumidor_final', 'credito', 'gubernamental'];

        // $clientes = [];
        // for ($i = 0; $i < 10000; $i++) {
        //     $clientes[] = [
        //         'nombre' => $faker->name . ' / ' . $faker->company,
        //         'rnc_cedula' => $faker->numerify('###-#######-#'),
        //         'email' => $faker->unique()->safeEmail,
        //         'telefono' => $faker->numerify('809-###-####'),
        //         'direccion' => $faker->address,
        //         'tipo_cliente' => $faker->randomElement($tipos),
        //         'cuenta_contable' => '1.1.03.0' . rand(1, 9),
        //         'limite_credito' => $faker->randomFloat(2, 0, 100000),
        //         'saldo_actual' => $faker->randomFloat(2, 0, 5000),
        //         'dias_credito' => $faker->randomElement([0, 15, 30, 60]),
        //         'activo' => true,
        //         'created_at' => now(),
        //         'updated_at' => now(),
        //     ];

        //     if (count($clientes) >= 1000) {
        //         \Illuminate\Support\Facades\DB::table('clientes')->insert($clientes);
        //         $clientes = [];
        //     }
        // }

        // if (count($clientes) > 0) {
        //     \Illuminate\Support\Facades\DB::table('clientes')->insert($clientes);
        // }
    }
}
