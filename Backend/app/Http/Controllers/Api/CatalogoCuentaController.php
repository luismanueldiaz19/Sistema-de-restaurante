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
}
