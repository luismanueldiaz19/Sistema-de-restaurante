<?php

namespace App\Http\Controllers\Api\Finanzas;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\MetodoPago;
use App\Models\BankAccount;

class MetodoPagoController extends Controller
{
    public function index()
    {
        return response()->json(MetodoPago::with('cuentaContable')->get());
    }

    public function activos()
    {
        return response()->json(MetodoPago::with('cuentaContable')->where('activo', true)->get());
    }

    public function store(Request $request)
    {
        $request->validate([
            'nombre' => 'required|string|max:255',
            'tipo' => 'required|in:efectivo,tarjeta,transferencia',
            'catalogo_cuenta_id' => 'nullable|exists:catalogo_cuentas,id',
            'activo' => 'boolean'
        ]);

        $data = $request->all();

        if (isset($data['catalogo_cuenta_id']) && $data['catalogo_cuenta_id']) {
            $bankAccount = BankAccount::where('accounting_account_id', $data['catalogo_cuenta_id'])->first();
            $data['bank_account_id'] = $bankAccount ? $bankAccount->id : null;
        }

        $metodo = MetodoPago::create($data);
        $metodo->load('cuentaContable');
        return response()->json($metodo, 201);
    }

    public function update(Request $request, $id)
    {
        $metodo = MetodoPago::findOrFail($id);

        $request->validate([
            'nombre' => 'sometimes|required|string|max:255',
            'tipo' => 'sometimes|required|in:efectivo,tarjeta,transferencia',
            'catalogo_cuenta_id' => 'nullable|exists:catalogo_cuentas,id',
            'activo' => 'boolean'
        ]);

        $data = $request->all();

        // Autocompletar el bank_account_id si se selecciona una cuenta contable que pertenece a un banco
        if (isset($data['catalogo_cuenta_id']) && $data['catalogo_cuenta_id']) {
            $bankAccount = BankAccount::where('accounting_account_id', $data['catalogo_cuenta_id'])->first();
            $data['bank_account_id'] = $bankAccount ? $bankAccount->id : null;
        }

        $metodo->update($data);
        $metodo->load('cuentaContable');
        return response()->json($metodo);
    }

    public function destroy($id)
    {
        $metodo = MetodoPago::findOrFail($id);
        $metodo->delete();
        return response()->json(['message' => 'Eliminado exitosamente']);
    }
}

