<?php

namespace Database\Seeders;

use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use App\Models\Bank;
use App\Models\BankAccount;
use App\Models\MetodoPago;
use App\Models\CatalogoCuenta;

class MetodoPagoCajaGeneralSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        // 1. Ensure a Bank exists for the Caja
        $bank = Bank::firstOrCreate(
            ['id' => 1],
            ['name' => 'Banco Interno / Caja', 'code' => 'CAJA', 'is_active' => true]
        );

        // 2. Ensure "Caja General" BankAccount exists with ID = 1
        $cajaGeneral = BankAccount::firstOrCreate(
            ['id' => 1],
            [
                'bank_id' => $bank->id,
                'name' => 'Caja General',
                'account_number' => '0000001',
                'currency' => 'DOP',
                'current_balance' => 0,
                'is_active' => true
            ]
        );

        // 3. Ensure the Metodo de Pago "Efectivo" exists and is linked to the Caja General and Catalogo Cuenta
        $cuentaCaja = CatalogoCuenta::where('codigo', '1.1.01.01')->first();
        
        $metodos = [
            ['nombre' => 'Efectivo', 'tipo' => 'efectivo'],
            ['nombre' => 'Tarjeta', 'tipo' => 'tarjeta'],
            ['nombre' => 'Transferencia', 'tipo' => 'transferencia'],
        ];

        foreach ($metodos as $metodo) {
            $m = MetodoPago::where('tipo', $metodo['tipo'])->first();
            if (!$m) {
                MetodoPago::create([
                    'nombre' => $metodo['nombre'],
                    'tipo' => $metodo['tipo'],
                    'bank_account_id' => $cajaGeneral->id,
                    'catalogo_cuenta_id' => $cuentaCaja ? $cuentaCaja->id : null,
                    'activo' => true
                ]);
            } else {
                $m->update([
                    'bank_account_id' => $cajaGeneral->id,
                    'catalogo_cuenta_id' => $cuentaCaja ? $cuentaCaja->id : null,
                ]);
            }
        }
    }
}
