<?php

declare(strict_types=1);

namespace App\Modules\Contabilidad\Http\Controllers;

use App\Http\Controllers\Controller;
use App\Models\AsientoContable;
use App\Modules\Contabilidad\Http\Requests\StoreAsientoManualRequest;
use App\Modules\Contabilidad\Services\ContabilidadService;
use App\Modules\Shared\Traits\ApiResponseTrait;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Throwable;

class AsientoContableController extends Controller
{
    use ApiResponseTrait;

    public function __construct(
        private readonly ContabilidadService $contabilidadService
    ) {}

    /**
     * Listar todos los asientos contables generados cronológicamente.
     */
    public function index(Request $request): JsonResponse
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

            $asientos = $query->paginate($request->integer('per_page', 15));

            return response()->json([
                'success' => true,
                'data' => $asientos,
            ]);
        } catch (Throwable $e) {
            return response()->json([
                'success' => false,
                'message' => 'Error al obtener los asientos contables: ' . $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Crear un asiento contable de forma manual.
     */
    public function store(StoreAsientoManualRequest $request): JsonResponse
    {
        try {
            $asiento = $this->contabilidadService->registrarAsientoManual(
                $request->only(['fecha', 'glosa', 'referencia']),
                $request->input('detalles'),
                $request->user()?->id
            );

            return response()->json([
                'success' => true,
                'message' => 'Asiento contable manual registrado correctamente',
                'data' => $asiento,
            ], 201);
        } catch (Throwable $e) {
            return response()->json([
                'success' => false,
                'message' => 'Error al registrar el asiento contable: ' . $e->getMessage(),
            ], 422);
        }
    }
}
