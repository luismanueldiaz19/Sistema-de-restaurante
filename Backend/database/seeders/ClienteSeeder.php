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

        Cliente::create([
            'nombre' => 'Juan Pérez (Crédito)',
            'rnc_cedula' => '001-1234567-8',
            'email' => 'juan@example.com',
            'telefono' => '809-555-1234',
            'tipo_cliente' => 'credito',
            'cuenta_contable' => '1.1.03.02',
            'limite_credito' => 50000,
            'saldo_actual' => 1500,
            'dias_credito' => 30,
            'activo' => true,
        ]);

        Cliente::create([
            'nombre' => 'Constructora Nacional',
            'rnc_cedula' => '1-31-01234-5',
            'email' => 'ventas@constructora.com',
            'tipo_cliente' => 'gubernamental',
            'cuenta_contable' => '1.1.03.03',
            'limite_credito' => 500000,
            'saldo_actual' => 0,
            'dias_credito' => 60,
            'activo' => true,
        ]);
    }
}
