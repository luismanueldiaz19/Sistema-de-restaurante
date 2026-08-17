<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\CatalogoCuenta;

class CatalogoCuentaController extends Controller
{
    /**
     * Display a listing of the chart of accounts.
     *
     * @param  \Illuminate\Http\Request  $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function index(Request $request)
    {
        try {
            $query = CatalogoCuenta::with('padre')->orderBy('codigo');

            if ($request->has('permite_movimiento')) {
                $query->where('permite_movimiento', filter_var($request->permite_movimiento, FILTER_VALIDATE_BOOLEAN));
            }

            $cuentas = $query->get();

            return response()->json([
                'status' => 200,
                'data' => $cuentas
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'status' => 500,
                'message' => 'Error al obtener el catálogo de cuentas',
                'error' => $e->getMessage()
            ], 500);
        }
    }
    /**
     * Store a newly created account in storage.
     */
    public function store(Request $request)
    {
        $validatedData = $request->validate([
            'codigo' => 'required|string|unique:catalogo_cuentas,codigo',
            'nombre' => 'required|string',
            'tipo' => 'required|in:Activo,Pasivo,Capital,Ingresos,Costos,Gastos',
            'nivel' => 'required|integer',
            'padre_id' => 'nullable|exists:catalogo_cuentas,id',
            'permite_movimiento' => 'required|boolean',
        ]);

        try {
            $cuenta = CatalogoCuenta::create($validatedData);

            return response()->json([
                'status' => 201,
                'data' => $cuenta,
                'message' => 'Cuenta creada exitosamente'
            ], 201);
        } catch (\Exception $e) {
            return response()->json([
                'status' => 500,
                'message' => 'Error al crear la cuenta',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Display the specified account.
     */
    public function show($id)
    {
        $cuenta = CatalogoCuenta::with('padre')->find($id);
        if (!$cuenta) {
            return response()->json(['status' => 404, 'message' => 'Cuenta no encontrada'], 404);
        }

        return response()->json([
            'status' => 200,
            'data' => $cuenta
        ]);
    }

    /**
     * Update the specified account in storage.
     */
    public function update(Request $request, $id)
    {
        $cuenta = CatalogoCuenta::find($id);
        if (!$cuenta) {
            return response()->json(['status' => 404, 'message' => 'Cuenta no encontrada'], 404);
        }

        $validatedData = $request->validate([
            'codigo' => 'sometimes|required|string|unique:catalogo_cuentas,codigo,'.$id,
            'nombre' => 'sometimes|required|string',
            'tipo' => 'sometimes|required|in:Activo,Pasivo,Capital,Ingresos,Costos,Gastos',
            'nivel' => 'sometimes|required|integer',
            'padre_id' => 'nullable|exists:catalogo_cuentas,id',
            'permite_movimiento' => 'sometimes|required|boolean',
        ]);

        try {
            $cuenta->update($validatedData);

            return response()->json([
                'status' => 200,
                'data' => $cuenta,
                'message' => 'Cuenta actualizada exitosamente'
            ], 200);
        } catch (\Exception $e) {
            return response()->json([
                'status' => 500,
                'message' => 'Error al actualizar la cuenta',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Remove the specified account from storage.
     */
    public function destroy($id)
    {
        $cuenta = CatalogoCuenta::find($id);
        if (!$cuenta) {
            return response()->json(['status' => 404, 'message' => 'Cuenta no encontrada'], 404);
        }

        try {
            // Verificación si tiene hijos
            $tieneHijos = CatalogoCuenta::where('padre_id', $id)->exists();
            if ($tieneHijos) {
                return response()->json([
                    'status' => 400,
                    'message' => 'No se puede eliminar la cuenta porque tiene subcuentas asociadas'
                ], 400);
            }

            $cuenta->delete();

            return response()->json([
                'status' => 200,
                'message' => 'Cuenta eliminada exitosamente'
            ], 200);
        } catch (\Exception $e) {
            return response()->json([
                'status' => 500,
                'message' => 'Error al eliminar la cuenta',
                'error' => $e->getMessage()
            ], 500);
        }
    }
}
