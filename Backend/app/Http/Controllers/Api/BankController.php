<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Bank;
use Illuminate\Http\Request;

class BankController extends Controller
{
    public function index()
    {
        $banks = Bank::all();
        return response()->json(['data' => $banks], 200);
    }

    public function store(Request $request)
    {
        $request->validate([
            'name' => 'required|string|max:255',
            'code' => 'nullable|string|max:50',
            'is_active' => 'boolean',
        ]);

        $bank = Bank::create($request->all());

        return response()->json(['data' => $bank, 'message' => 'Banco creado exitosamente'], 201);
    }

    public function show($id)
    {
        $bank = Bank::findOrFail($id);
        return response()->json(['data' => $bank], 200);
    }

    public function update(Request $request, $id)
    {
        $bank = Bank::findOrFail($id);

        $request->validate([
            'name' => 'sometimes|required|string|max:255',
            'code' => 'nullable|string|max:50',
            'is_active' => 'boolean',
        ]);

        $bank->update($request->all());

        return response()->json(['data' => $bank, 'message' => 'Banco actualizado'], 200);
    }

    public function destroy($id)
    {
        $bank = Bank::findOrFail($id);
        
        if ($bank->accounts()->exists()) {
            return response()->json(['message' => 'No se puede eliminar el banco porque tiene cuentas asociadas.'], 400);
        }

        $bank->delete();
        return response()->json(['message' => 'Banco eliminado'], 200);
    }
}
