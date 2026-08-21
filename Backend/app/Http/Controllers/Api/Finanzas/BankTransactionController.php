<?php

namespace App\Http\Controllers\Api\Finanzas;

use App\Http\Controllers\Controller;
use App\Models\BankAccount;
use App\Models\BankTransaction;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class BankTransactionController extends Controller
{
    public function index(Request $request)
    {
        $query = BankTransaction::with(['bankAccount']);

        if ($request->has('bank_account_id')) {
            $query->where('bank_account_id', $request->bank_account_id);
        }

        $transactions = $query->orderBy('date', 'desc')->orderBy('id', 'desc')->get();

        return response()->json(['data' => $transactions], 200);
    }

    public function store(Request $request)
    {
        $request->validate([
            'bank_account_id' => 'required|exists:bank_accounts,id',
            'date' => 'required|date',
            'type' => 'required|string|in:deposit,withdrawal,fee,interest,transfer',
            'amount' => 'required|numeric',
            'reference' => 'nullable|string|max:255',
            'description' => 'nullable|string',
        ]);

        try {
            DB::beginTransaction();

            $account = BankAccount::findOrFail($request->bank_account_id);
            $amount = $request->amount;
            
            // Adjust balance logic
            $balanceAdjustment = $amount;
            if (in_array($request->type, ['withdrawal', 'fee'])) {
                $balanceAdjustment = -abs($amount);
                $amount = -abs($amount); // store as negative
            } else if (in_array($request->type, ['deposit', 'interest'])) {
                $balanceAdjustment = abs($amount);
                $amount = abs($amount); // store as positive
            }

            $transaction = BankTransaction::create([
                'bank_account_id' => $request->bank_account_id,
                'date' => $request->date,
                'type' => $request->type,
                'amount' => $amount,
                'reference' => $request->reference,
                'description' => $request->description,
                'status' => 'pending', // default
                'journal_entry_id' => null, // The user specified: "hasta ahora no bamos hacer aciento contable hasta el momente, pero no dejamos de enviar el id de esto para luegos."
            ]);

            $account->current_balance += $balanceAdjustment;
            $account->save();

            DB::commit();

            return response()->json(['data' => $transaction, 'message' => 'Transacción registrada'], 201);

        } catch (\Exception $e) {
            DB::rollBack();
            return response()->json(['message' => 'Error al registrar la transacción: ' . $e->getMessage()], 500);
        }
    }

    public function reconcile(Request $request)
    {
        $request->validate([
            'transaction_ids' => 'required|array',
            'transaction_ids.*' => 'integer|exists:bank_transactions,id',
        ]);

        try {
            DB::beginTransaction();

            BankTransaction::whereIn('id', $request->transaction_ids)
                ->update(['status' => 'completed']);

            DB::commit();

            return response()->json(['message' => 'Transacciones conciliadas exitosamente'], 200);
        } catch (\Exception $e) {
            DB::rollBack();
            return response()->json(['message' => 'Error al conciliar transacciones: ' . $e->getMessage()], 500);
        }
    }
}

