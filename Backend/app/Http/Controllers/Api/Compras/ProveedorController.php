<?php

namespace App\Http\Controllers\Api\Compras;

use App\Http\Controllers\Controller;
use App\Models\Proveedor;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class ProveedorController extends Controller
{
    public function index()
    {
        return response()->json(Proveedor::with(['cuentaCxp', 'cuentaGasto'])->get());
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'nombre' => 'required|string|max:255',
            'rnc' => 'nullable|string|max:50',
            'telefono' => 'nullable|string|max:50',
            'email' => 'nullable|email|max:255',
            'direccion' => 'nullable|string',
            'cuenta_contable_cxp_id' => 'nullable|exists:catalogo_cuentas,id',
            'cuenta_contable_gasto_id' => 'nullable|exists:catalogo_cuentas,id',
            'activo' => 'boolean',
        ]);

        $proveedor = Proveedor::create($validated);
        return response()->json($proveedor, 201);
    }

    public function show($id)
    {
        $proveedor = Proveedor::with(['cuentaCxp', 'cuentaGasto'])->findOrFail($id);
        return response()->json($proveedor);
    }

    public function update(Request $request, $id)
    {
        $proveedor = Proveedor::findOrFail($id);

        $validated = $request->validate([
            'nombre' => 'required|string|max:255',
            'rnc' => 'nullable|string|max:50',
            'telefono' => 'nullable|string|max:50',
            'email' => 'nullable|email|max:255',
            'direccion' => 'nullable|string',
            'cuenta_contable_cxp_id' => 'nullable|exists:catalogo_cuentas,id',
            'cuenta_contable_gasto_id' => 'nullable|exists:catalogo_cuentas,id',
            'activo' => 'boolean',
        ]);

        $proveedor->update($validated);
        return response()->json($proveedor);
    }

    public function destroy($id)
    {
        $proveedor = Proveedor::findOrFail($id);
        // Ensure no relations prevent deletion
        if ($proveedor->compras()->exists()) {
            return response()->json(['message' => 'No se puede eliminar el proveedor porque tiene compras asociadas.'], 400);
        }
        $proveedor->delete();
        return response()->json(['message' => 'Proveedor eliminado']);
    }
}

