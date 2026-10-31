<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\Bank;
use App\Models\BankAccount;
use App\Models\CatalogoCuenta;
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
            ['name' => 'Caja General', 'code' => 'CAJA', 'is_active' => true],
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

        foreach ($banks as $bankData) {
            $bank = Bank::firstOrCreate(
                ['name' => $bankData['name']],
                $bankData
            );

            // Si es la Caja General, crear su cuenta bancaria automáticamente
            if ($bankData['code'] === 'CAJA') {
                // Buscar la cuenta contable de Caja General (usualmente 1.1.01.01)
                $cuentaContable = CatalogoCuenta::where('codigo', '1.1.01.01')->first();

                BankAccount::firstOrCreate(
                    ['bank_id' => $bank->id, 'name' => 'Caja General'],
                    [
                        'account_number' => '0000001',
                        'currency' => 'DOP',
                        'current_balance' => 0,
                        'accounting_account_id' => $cuentaContable->id, // Ahora es obligatorio
                        'is_active' => true,
                    ]
                );
            }
        }
    }
}
