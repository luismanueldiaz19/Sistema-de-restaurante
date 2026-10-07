<?php

declare(strict_types=1);

namespace App\Modules\Cotizacion\Http\Controllers;

use App\Http\Controllers\Controller;
use App\Modules\Cotizacion\DTOs\CreateCotizacionDTO;
use App\Modules\Cotizacion\Http\Requests\StoreCotizacionRequest;
use App\Modules\Cotizacion\Http\Requests\UpdateCotizacionStatusRequest;
use App\Modules\Cotizacion\Services\CotizacionService;
use App\Modules\Shared\Traits\ApiResponseTrait;
use App\Models\Cotizacion;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Str;
use Barryvdh\DomPDF\Facade\Pdf;

class CotizacionController extends Controller
{
    use ApiResponseTrait;

    public function __construct(
        private readonly CotizacionService $cotizacionService
    ) {}

    public function store(StoreCotizacionRequest $request): JsonResponse
    {
        try {
            $dto = CreateCotizacionDTO::fromRequest($request);
            $result = $this->cotizacionService->create($dto);

            return $this->successResponse(
                data: $result,
                message: 'Cotización creada correctamente',
                code: 201
            );
        } catch (\Exception $e) {
            return $this->errorResponse(
                message: 'Error al crear la cotización: ' . $e->getMessage(),
                code: 500
            );
        }
    }

    public function index(Request $request): JsonResponse
    {
        $query = Cotizacion::with(['cliente', 'user'])->orderBy('fecha_emision', 'desc');

        if ($request->filled('fecha_desde')) {
            $query->where('fecha_emision', '>=', $request->fecha_desde);
        }

        if ($request->filled('fecha_hasta')) {
            $query->where('fecha_emision', '<=', $request->fecha_hasta . ' 23:59:59');
        }

        if ($request->filled('cliente_id')) {
            $query->where('cliente_id', $request->cliente_id);
        }

        if ($request->filled('estado') && $request->estado !== 'todos') {
            $query->where('estado', $request->estado);
        }

        if ($request->filled('search')) {
            $search = $request->search;
            $idSearch = preg_replace('/[^0-9]/', '', $search);

            $query->where(function ($q) use ($search, $idSearch) {
                if (!empty($idSearch)) {
                    $q->where('id', $idSearch);
                }
                $q->orWhereHas('cliente', function ($q2) use ($search) {
                    $q2->where('nombre', 'LIKE', "%{$search}%")
                       ->orWhere('rnc_cedula', 'LIKE', "%{$search}%");
                });
            });
        }

        $resumenQuery = clone $query;
        $totales = $resumenQuery->reorder()->selectRaw('
            COUNT(*) as cantidad_cotizaciones, 
            SUM(total) as total_monto
        ')->first();

        $cotizaciones = $query->paginate($request->per_page ?? 15);

        $cotizaciones->getCollection()->transform(function ($cotizacion) use ($request) {
            $token = Str::random(40);
            Cache::put("short_link_{$token}", [
                'type' => 'cotizacion',
                'id' => $cotizacion->id,
                'companyData' => [
                    'company_name' => $request->company_name,
                    'company_rnc' => $request->company_rnc,
                    'company_address' => $request->company_address,
                    'company_phone' => $request->company_phone,
                ]
            ], now()->addHours(24));

            $cotizacion->pdf_url = "/d/{$token}";
            return $cotizacion;
        });

        return response()->json([
            'status' => true,
            'data'   => $cotizaciones,
            'resumen' => $totales
        ]);
    }

    public function show(Request $request, int $id): JsonResponse
    {
        try {
            $cotizacion = Cotizacion::with(['cliente', 'detalles', 'user'])->find($id);

            if (!$cotizacion) {
                return $this->errorResponse('Cotización no encontrada', 404);
            }

            $token = Str::random(40);
            Cache::put("short_link_{$token}", [
                'type' => 'cotizacion',
                'id' => $cotizacion->id,
                'companyData' => [
                    'company_name' => $request->company_name,
                    'company_rnc' => $request->company_rnc,
                    'company_address' => $request->company_address,
                    'company_phone' => $request->company_phone,
                ]
            ], now()->addHours(24));

            $cotizacion->pdf_url = "/d/{$token}";

            return $this->successResponse(
                data: $cotizacion,
                message: 'Cotización encontrada'
            );
        } catch (\Exception $e) {
            return $this->errorResponse('Error al obtener la cotización: ' . $e->getMessage(), 500);
        }
    }

    public function updateStatus(UpdateCotizacionStatusRequest $request, int $id): JsonResponse
    {
        $cotizacion = Cotizacion::find($id);
        if (!$cotizacion) {
            return $this->errorResponse('No encontrada', 404);
        }

        $cotizacion->estado = $request->validated('estado');
        $cotizacion->save();

        return $this->successResponse(
            message: 'Estado actualizado a ' . $cotizacion->estado
        );
    }

}
