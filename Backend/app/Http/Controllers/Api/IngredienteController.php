<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Ingrediente;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;
use Exception;

class IngredienteController extends Controller
{
    /**
     * Display a listing of the resource.
     */
    public function index()
    {
        $ingredientes = Ingrediente::latest()->get();
        return response()->json($ingredientes);
    }

    /**
     * Store a newly created resource in storage.
     */
    public function store(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'nombre'         => 'required|string|max:100',
            'unidad'         => 'nullable|string|max:20',
            'stock'          => 'nullable|numeric',
            'costo_unitario' => 'nullable|numeric',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'message' => 'Error en la validación',
                'errors' => $validator->errors()
            ], 400);
        }

        try {
            $ingrediente = Ingrediente::create($request->all());
            return response()->json([
                'message' => 'Ingrediente creado correctamente',
                'data' => $ingrediente
            ], 201);
        } catch (Exception $e) {
            return response()->json([
                'message' => 'Error al crear ingrediente',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Display the specified resource.
     */
    public function show(string $id)
    {
        $ingrediente = Ingrediente::find($id);
        if (!$ingrediente) {
            return response()->json(['message' => 'Ingrediente no encontrado'], 404);
        }
        return response()->json($ingrediente);
    }

    /**
     * Update the specified resource in storage.
     */
    public function update(Request $request, string $id)
    {
        $ingrediente = Ingrediente::find($id);
        if (!$ingrediente) {
            return response()->json(['message' => 'Ingrediente no encontrado'], 404);
        }

        $validator = Validator::make($request->all(), [
            'nombre'         => 'required|string|max:100',
            'unidad'         => 'nullable|string|max:20',
            'stock'          => 'nullable|numeric',
            'costo_unitario' => 'nullable|numeric',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'message' => 'Error en la validación',
                'errors' => $validator->errors()
            ], 400);
        }

        try {
            $ingrediente->update($request->all());
            return response()->json([
                'message' => 'Ingrediente actualizado correctamente',
                'data' => $ingrediente
            ], 200);
        } catch (Exception $e) {
            return response()->json([
                'message' => 'Error al actualizar ingrediente',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Remove the specified resource from storage.
     */
    public function destroy(string $id)
    {
        $ingrediente = Ingrediente::find($id);
        if (!$ingrediente) {
            return response()->json(['message' => 'Ingrediente no encontrado'], 404);
        }

        try {
            // Validar si tiene recetas asociadas
            if ($ingrediente->recetas()->count() > 0) {
                return response()->json([
                    'message' => 'No se puede eliminar un ingrediente que forma parte de una receta activa.'
                ], 400);
            }

            $ingrediente->delete();
            return response()->json(['message' => 'Ingrediente eliminado correctamente'], 200);
        } catch (Exception $e) {
            return response()->json([
                'message' => 'Error al eliminar ingrediente',
                'error' => $e->getMessage()
            ], 500);
        }
    }
}
