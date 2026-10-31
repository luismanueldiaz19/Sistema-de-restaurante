<?php

namespace App\Http\Controllers\Api\Finanzas;

use App\Http\Controllers\Controller;
use App\Models\BankAccount;
use Illuminate\Http\Request;

class BankAccountController extends Controller
{
    public function index()
    {
        $accounts = BankAccount::with(['bank', 'accountingAccount'])->get();
        return response()->json(['data' => $accounts], 200);
    }

    public function store(Request $request)
    {
        $request->validate([
            'bank_id' => 'required|exists:banks,id',
            'name' => 'required|string|max:255',
            'account_number' => 'required|string|max:100',
            'currency' => 'string|max:10',
            'current_balance' => 'numeric',
            'accounting_account_id' => 'nullable|exists:catalogo_cuentas,id',
            'is_active' => 'boolean',
        ]);

        $account = BankAccount::create($request->all());
        $account->load(['bank', 'accountingAccount']);

        return response()->json(['data' => $account, 'message' => 'Cuenta creada exitosamente'], 201);
    }

    public function show($id)
    {
        $account = BankAccount::with(['bank', 'accountingAccount'])->findOrFail($id);
        return response()->json(['data' => $account], 200);
    }

    public function update(Request $request, $id)
    {
        $account = BankAccount::findOrFail($id);

        $request->validate([
            'bank_id' => 'sometimes|required|exists:banks,id',
            'name' => 'sometimes|required|string|max:255',
            'account_number' => 'sometimes|required|string|max:100',
            'currency' => 'string|max:10',
            'current_balance' => 'numeric',
            'accounting_account_id' => 'nullable|exists:catalogo_cuentas,id',
            'is_active' => 'boolean',
        ]);

        $account->update($request->all());
        $account->load(['bank', 'accountingAccount']);

        return response()->json(['data' => $account, 'message' => 'Cuenta actualizada'], 200);
    }

    public function destroy($id)
    {
        $account = BankAccount::findOrFail($id);
        
        if ($account->transactions()->exists()) {
            return response()->json(['message' => 'No se puede eliminar la cuenta porque tiene transacciones.'], 400);
        }

        $account->delete();
        return response()->json(['message' => 'Cuenta eliminada'], 200);
    }
}

