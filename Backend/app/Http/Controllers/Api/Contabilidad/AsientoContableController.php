<?php

namespace App\Http\Controllers\Api\Contabilidad;

use App\Http\Controllers\Controller;
use App\Models\AsientoContable;
use Illuminate\Http\Request;

class AsientoContableController extends Controller
{
    /**
     * Listar todos los asientos contables generados cronológicamente.
     */
    public function index(Request $request)
    {
        try {
            $query = AsientoContable::with(['detalles.cuenta', 'usuario'])
                ->orderBy('fecha', 'desc')
                ->orderBy('id', 'desc');

            // Filtrado por rango de fechas
            if ($request->filled('fecha_desde')) {
                $query->where('fecha', '>=', $request->fecha_desde);
            }
            if ($request->filled('fecha_hasta')) {
                $query->where('fecha', '<=', $request->fecha_hasta);
            }

            // Búsqueda por referencia o glosa
            if ($request->filled('buscar')) {
                $buscar = '%' . $request->buscar . '%';
                $query->where(function ($q) use ($buscar) {
                    $q->where('referencia', 'like', $buscar)
                      ->orWhere('glosa', 'like', $buscar);
                });
            }

            $asientos = $query->paginate($request->per_page ?? 15);

            return response()->json([
                'success' => true,
                'data' => $asientos,
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Error al obtener los asientos contables: ' . $e->getMessage(),
            ], 500);
        }
    }
}

