<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Categoria;
use Illuminate\Http\Request;

class CategoriaController extends Controller
{
    public function index()
    {
        return response()->json(['success' => true, 'data' => Categoria::all()]);
    }

    public function store(Request $request)
    {
        $Categoria = Categoria::create($request->all());
        return response()->json(['success' => true, 'data' => $Categoria], 201);
    }

    public function show($id)
    {
        return response()->json(['success' => true, 'data' => Categoria::findOrFail($id)]);
    }

    public function update(Request $request, $id)
    {
        $Categoria = Categoria::findOrFail($id);
        $Categoria->update($request->all());
        return response()->json(['success' => true, 'data' => $Categoria]);
    }

    public function destroy($id)
    {
        $Categoria = Categoria::findOrFail($id);
        $Categoria->delete();
        return response()->json(['success' => true, 'message' => 'Eliminado exitosamente']);
    }
}
