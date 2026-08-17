<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\MetodoPago;

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

        $metodo = MetodoPago::create($request->all());
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

        $metodo->update($request->all());
        return response()->json($metodo);
    }

    public function destroy($id)
    {
        $metodo = MetodoPago::findOrFail($id);
        $metodo->delete();
        return response()->json(['message' => 'Eliminado exitosamente']);
    }
}
