<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\Bank;

class BankSeeder extends Seeder
{
    /**
     * Run the database seeds.
     *
     * @return void
     */
    public function run()
    {
        $banks = [
            ['name' => 'Banco Interno / Caja', 'code' => 'CAJA', 'is_active' => true],
            ['name' => 'Banco de Reservas', 'code' => 'BR', 'is_active' => true],
            ['name' => 'Banco Popular Dominicano', 'code' => 'BPD', 'is_active' => true],
            ['name' => 'Banco BHD', 'code' => 'BHD', 'is_active' => true],
            ['name' => 'Scotiabank', 'code' => 'BNS', 'is_active' => true],
            ['name' => 'Asociación Popular de Ahorros y Préstamos', 'code' => 'APAP', 'is_active' => true],
            ['name' => 'Asociación Cibao de Ahorros y Préstamos', 'code' => 'ACAP', 'is_active' => true],
            ['name' => 'Banco Santa Cruz', 'code' => 'BSC', 'is_active' => true],
            ['name' => 'Banco Caribe', 'code' => 'BCA', 'is_active' => true],
            ['name' => 'Banco BDI', 'code' => 'BDI', 'is_active' => true],
            ['name' => 'CitiBank', 'code' => 'CITI', 'is_active' => true],
        ];

        foreach ($banks as $bank) {
            Bank::firstOrCreate(
                ['name' => $bank['name']],
                $bank
            );
        }
    }
}
