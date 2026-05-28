<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Marca;
use Illuminate\Http\Request;

class MarcaController extends Controller
{
    public function index()
    {
        return response()->json(['success' => true, 'data' => Marca::all()]);
    }

    public function store(Request $request)
    {
        $Marca = Marca::create($request->all());
        return response()->json(['success' => true, 'data' => $Marca], 201);
    }

    public function show($id)
    {
        return response()->json(['success' => true, 'data' => Marca::findOrFail($id)]);
    }

    public function update(Request $request, $id)
    {
        $Marca = Marca::findOrFail($id);
        $Marca->update($request->all());
        return response()->json(['success' => true, 'data' => $Marca]);
    }

    public function destroy($id)
    {
        $Marca = Marca::findOrFail($id);
        $Marca->delete();
        return response()->json(['success' => true, 'message' => 'Eliminado exitosamente']);
    }
}
