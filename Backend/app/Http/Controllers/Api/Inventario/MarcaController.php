<?php

namespace App\Http\Controllers\Api\Inventario;

use App\Http\Controllers\Controller;
use App\Models\Marca;
use Illuminate\Http\Request;

class MarcaController extends Controller
{
    public function index(Request $request)
    {
        $items = Marca::all();
        if ($request->has('search') && $request->search != '') {
            $search = $this->normalizarTexto($request->search);
            $items = $items->filter(function ($item) use ($search) {
                return str_contains($this->normalizarTexto($item->nombre), $search);
            })->values();
        }
        return response()->json(['success' => true, 'data' => $items]);
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

