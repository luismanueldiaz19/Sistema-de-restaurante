<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\UnidadMedida;
use Illuminate\Http\Request;

class UnidadMedidaController extends Controller
{
    public function index()
    {
        return response()->json(['success' => true, 'data' => UnidadMedida::all()]);
    }

    public function store(Request $request)
    {
        $UnidadMedida = UnidadMedida::create($request->all());
        return response()->json(['success' => true, 'data' => $UnidadMedida], 201);
    }

    public function show($id)
    {
        return response()->json(['success' => true, 'data' => UnidadMedida::findOrFail($id)]);
    }

    public function update(Request $request, $id)
    {
        $UnidadMedida = UnidadMedida::findOrFail($id);
        $UnidadMedida->update($request->all());
        return response()->json(['success' => true, 'data' => $UnidadMedida]);
    }

    public function destroy($id)
    {
        $UnidadMedida = UnidadMedida::findOrFail($id);
        $UnidadMedida->delete();
        return response()->json(['success' => true, 'message' => 'Eliminado exitosamente']);
    }
}
