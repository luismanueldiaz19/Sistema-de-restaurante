<?php

declare(strict_types=1);

namespace App\Modules\Compra\Http\Controllers;

use App\Http\Controllers\Controller;
use App\Modules\Compra\DTOs\CreateCompraDTO;
use App\Modules\Compra\Http\Requests\StoreCompraRequest;
use App\Modules\Compra\Services\CompraService;
use App\Modules\Shared\Traits\ApiResponseTrait;
use App\Models\Compra;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;

class CompraController extends Controller
{
    use ApiResponseTrait;

    public function __construct(
        private readonly CompraService $compraService
    ) {}

    public function index(Request $request): JsonResponse
    {
        $query = Compra::with(['proveedor', 'detalles.producto', 'usuario', 'cuentaPorPagar'])
            ->orderBy('id', 'desc');

        if ($request->filled('fecha_desde')) {
            $query->where('fecha_compra', '>=', $request->fecha_desde);
        }

        if ($request->filled('fecha_hasta')) {
            $query->where('fecha_compra', '<=', $request->fecha_hasta . ' 23:59:59');
        }

        if ($request->filled('estado') && $request->estado !== 'todos') {
            $query->where('estado', $request->estado);
        }

        if ($request->filled('search')) {
            $search = strtolower($request->search);
            $query->where(function($q) use ($search) {
                $q->whereRaw('LOWER(numero_factura_proveedor) LIKE ?', ["%{$search}%"])
                  ->orWhereRaw('LOWER(ncf) LIKE ?', ["%{$search}%"])
                  ->orWhereRaw('LOWER(notas) LIKE ?', ["%{$search}%"])
                  ->orWhereHas('proveedor', function($p) use ($search) {
                      $p->whereRaw('LOWER(nombre) LIKE ?', ["%{$search}%"]);
                  });
            });
        }

        $compras = $query->paginate((int)$request->input('per_page', 20));

        return $this->successResponse(
            data: $compras,
            message: 'Lista de compras'
        );
    }

    public function store(StoreCompraRequest $request): JsonResponse
    {
        try {
            $dto = CreateCompraDTO::fromRequest($request);
            $result = $this->compraService->create($dto);

            return $this->successResponse(
                data: $result,
                message: 'Compra registrada correctamente',
                code: 201
            );
        } catch (\Exception $e) {
            return $this->errorResponse(
                message: 'Error al registrar la compra: ' . $e->getMessage(),
                code: 400
            );
        }
    }

    public function show(int $id): JsonResponse
    {
        $compra = Compra::with(['proveedor', 'detalles.producto', 'usuario', 'cuentaPorPagar'])->find($id);

        if (!$compra) {
            return $this->errorResponse('Compra no encontrada', 404);
        }

        return $this->successResponse(
            data: $compra,
            message: 'Detalle de la compra'
        );
    }
}
