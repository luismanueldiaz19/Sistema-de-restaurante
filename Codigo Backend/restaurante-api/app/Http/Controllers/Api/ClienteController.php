<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Cliente;
use Illuminate\Http\Request;

class ClienteController extends Controller
{
    // 🔍 LISTAR
    public function index()
    {
        $clientes = Cliente::latest()->get();
        return response()->json($clientes);
    }

    // ➕ CREAR
    public function store(Request $request)
    {
        $request->validate([
            'nombre' => 'required'
        ]);

        $cliente = Cliente::create($request->all());

        return response()->json([
            'status'  => true,
            'message' => 'Cliente creado',
            'data'    => $cliente
        ]);
    }

    // 🔍 VER UNO
    public function show($id)
    {
        $cliente = Cliente::findOrFail($id);
        return response()->json($cliente);
    }

    // ✏️ ACTUALIZAR
    public function update(Request $request, $id)
    {
        $cliente = Cliente::findOrFail($id);

        $request->validate([
            'nombre' => 'required'
        ]);

        $cliente->update($request->only([
            'nombre',
            'telefono',
            'direccion',
            'documento',
            'email'
        ]));

        return response()->json([
            'status'  => true,
            'message' => 'Cliente actualizado correctamente',
            'data'    => $cliente
        ]);
    }

    // ❌ ELIMINAR
    public function destroy($id)
    {
        $cliente = Cliente::findOrFail($id);
        $cliente->delete();

        return response()->json([
            'status'  => true,
            'message' => 'Cliente eliminado'
        ]);
    }

}
