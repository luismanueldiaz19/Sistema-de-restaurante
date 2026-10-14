<?php

declare(strict_types=1);

namespace App\Modules\Contabilidad\Http\Controllers;

use App\Http\Controllers\Controller;
use App\Models\CatalogoCuenta;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Throwable;

class CatalogoCuentaController extends Controller
{
    /**
     * Display a listing of the chart of accounts.
     */
    public function index(Request $request): JsonResponse
    {
        try {
            $query = CatalogoCuenta::with('padre')->orderBy('codigo');

            if ($request->has('permite_movimiento')) {
                $query->where('permite_movimiento', filter_var($request->permite_movimiento, FILTER_VALIDATE_BOOLEAN));
            }

            $cuentas = $query->get();

            return response()->json([
                'status' => 200,
                'success' => true,
                'data' => $cuentas,
            ]);
        } catch (Throwable $e) {
            return response()->json([
                'status' => 500,
                'success' => false,
                'message' => 'Error al obtener el catálogo de cuentas: ' . $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Store a newly created account in storage.
     */
    public function store(Request $request): JsonResponse
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
                'success' => true,
                'data' => $cuenta,
                'message' => 'Cuenta creada exitosamente',
            ], 201);
        } catch (Throwable $e) {
            return response()->json([
                'status' => 500,
                'success' => false,
                'message' => 'Error al crear la cuenta: ' . $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Display the specified account.
     */
    public function show(int $id): JsonResponse
    {
        $cuenta = CatalogoCuenta::with('padre')->find($id);
        if (!$cuenta) {
            return response()->json(['status' => 404, 'success' => false, 'message' => 'Cuenta no encontrada'], 404);
        }

        return response()->json([
            'status' => 200,
            'success' => true,
            'data' => $cuenta,
        ]);
    }

    /**
     * Update the specified account in storage.
     */
    public function update(Request $request, int $id): JsonResponse
    {
        $cuenta = CatalogoCuenta::find($id);
        if (!$cuenta) {
            return response()->json(['status' => 404, 'success' => false, 'message' => 'Cuenta no encontrada'], 404);
        }

        $validatedData = $request->validate([
            'codigo' => 'sometimes|required|string|unique:catalogo_cuentas,codigo,' . $id,
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
                'success' => true,
                'data' => $cuenta,
                'message' => 'Cuenta actualizada exitosamente',
            ], 200);
        } catch (Throwable $e) {
            return response()->json([
                'status' => 500,
                'success' => false,
                'message' => 'Error al actualizar la cuenta: ' . $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Remove the specified account from storage.
     */
    public function destroy(int $id): JsonResponse
    {
        $cuenta = CatalogoCuenta::find($id);
        if (!$cuenta) {
            return response()->json(['status' => 404, 'success' => false, 'message' => 'Cuenta no encontrada'], 404);
        }

        try {
            $tieneHijos = CatalogoCuenta::where('padre_id', $id)->exists();
            if ($tieneHijos) {
                return response()->json([
                    'status' => 400,
                    'success' => false,
                    'message' => 'No se puede eliminar la cuenta porque tiene subcuentas asociadas',
                ], 400);
            }

            $cuenta->delete();

            return response()->json([
                'status' => 200,
                'success' => true,
                'message' => 'Cuenta eliminada exitosamente',
            ], 200);
        } catch (Throwable $e) {
            return response()->json([
                'status' => 500,
                'success' => false,
                'message' => 'Error al eliminar la cuenta: ' . $e->getMessage(),
            ], 500);
        }
    }
}
