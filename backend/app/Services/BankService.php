<?php

namespace App\Services;

use App\Models\BankAccount;
use App\Models\BankTransaction;
use Illuminate\Support\Facades\DB;
use Exception;

class BankService
{
    /**
     * Registra una transacción bancaria afectando el balance de forma segura.
     * Se asume que este método se llama dentro de una transacción de base de datos activa (DB::beginTransaction).
     *
     * @param int $bankAccountId
     * @param string $type 'deposit', 'withdrawal', 'fee', 'interest', 'transfer'
     * @param float $amount
     * @param string|null $reference
     * @param string|null $description
     * @param int|null $journalEntryId ID del Asiento Contable generado
     * @return BankTransaction
     * @throws Exception
     */
    public function registrarTransaccion($bankAccountId, $type, $amount, $reference = null, $description = null, $journalEntryId = null)
    {
        // Bloquear la cuenta bancaria para escritura concurrente y prevenir race conditions
        $account = BankAccount::with('bank')->where('id', $bankAccountId)->lockForUpdate()->first();

        if (!$account) {
            throw new Exception("Cuenta bancaria no encontrada para el ID: $bankAccountId");
        }

        // Determinar el ajuste del balance y el monto a guardar
        $balanceAdjustment = $amount;
        $transactionAmount = $amount;
        
        if (in_array($type, ['withdrawal', 'fee'])) {
            $balanceAdjustment = -abs($amount);
            $transactionAmount = -abs($amount); // Guardar como negativo
        } else if (in_array($type, ['deposit', 'interest'])) {
            $balanceAdjustment = abs($amount);
            $transactionAmount = abs($amount); // Guardar como positivo
        } else if ($type === 'transfer') {
             // En transferencias, dependerá si entra o sale, pero por ahora lo dejamos como viene o manejado por lógica superior
             $balanceAdjustment = $amount;
             $transactionAmount = $amount;
        }

        // Determinar el estado de la transacción basado en si es una cuenta de banco o de caja
        $isCaja = $account->bank && $account->bank->code === 'CAJA';
        $status = $isCaja ? 'completed' : 'pending';

        // Crear la transacción
        $transaction = BankTransaction::create([
            'bank_account_id'  => $bankAccountId,
            'date'             => now()->toDateString(), // Usamos solo la fecha, a menos que el campo acepte datetime
            'type'             => $type,
            'amount'           => $transactionAmount,
            'reference'        => $reference,
            'description'      => $description,
            'status'           => $status, // Si es CAJA se completa automático, si es Banco queda pendiente para conciliar
            'journal_entry_id' => $journalEntryId,
        ]);

        // Actualizar el balance
        $account->current_balance += $balanceAdjustment;
        $account->save();

        return $transaction;
    }
}
