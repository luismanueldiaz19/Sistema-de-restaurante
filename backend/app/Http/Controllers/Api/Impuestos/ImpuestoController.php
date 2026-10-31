<?php

namespace App\Http\Controllers\Api\Impuestos;

use App\Http\Controllers\Controller;
use App\Models\Impuesto;
use Illuminate\Http\Request;

class ImpuestoController extends Controller
{
    public function index()
    {
        return response()->json(['success' => true, 'data' => Impuesto::all()]);
    }

    public function store(Request $request)
    {
        $Impuesto = Impuesto::create($request->all());
        return response()->json(['success' => true, 'data' => $Impuesto], 201);
    }

    public function show($id)
    {
        return response()->json(['success' => true, 'data' => Impuesto::findOrFail($id)]);
    }

    public function update(Request $request, $id)
    {
        $Impuesto = Impuesto::findOrFail($id);
        $Impuesto->update($request->all());
        return response()->json(['success' => true, 'data' => $Impuesto]);
    }

    public function destroy($id)
    {
        $Impuesto = Impuesto::findOrFail($id);
        $Impuesto->delete();
        return response()->json(['success' => true, 'message' => 'Eliminado exitosamente']);
    }
}

