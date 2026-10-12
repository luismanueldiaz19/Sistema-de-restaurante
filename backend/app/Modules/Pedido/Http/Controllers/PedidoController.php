<?php

declare(strict_types=1);

namespace App\Modules\Pedido\Http\Controllers;

use App\Http\Controllers\Controller;
use App\Modules\Pedido\DTOs\CreatePedidoDTO;
use App\Modules\Pedido\Http\Requests\StorePedidoRequest;
use App\Modules\Pedido\Http\Requests\UpdatePedidoStatusRequest;
use App\Modules\Pedido\Services\PedidoService;
use App\Modules\Shared\Traits\ApiResponseTrait;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;

class PedidoController extends Controller
{
    use ApiResponseTrait;

    public function __construct(
        private readonly PedidoService $pedidoService
    ) {}

    public function index(Request $request): JsonResponse
    {
        $fecha = $request->query('fecha', date('Y-m-d'));
        $pedidos = $this->pedidoService->getByDate($fecha);

        return response()->json([
            'success' => true,
            'message' => 'Lista de pedidos',
            'data'    => $pedidos,
        ]);
    }

    public function show(int $id): JsonResponse
    {
        $pedido = $this->pedidoService->findById($id);

        if (!$pedido) {
            return $this->errorResponse('Pedido no encontrado', 404);
        }

        return response()->json([
            'success' => true,
            'message' => 'Pedido encontrado',
            'pedido'  => $pedido,
            'data'    => $pedido,
        ]);
    }

    public function getByCodigo(string $codigo): JsonResponse
    {
        $pedido = $this->pedidoService->getByCodigo($codigo);

        if (!$pedido) {
            return response()->json([
                'success' => false,
                'message' => 'Pedido no encontrado',
            ], 404);
        }

        return response()->json([
            'success' => true,
            'message' => 'Pedido encontrado',
            'pedido'  => $pedido,
            'data'    => $pedido,
        ]);
    }

    public function store(StorePedidoRequest $request): JsonResponse
    {
        try {
            $dto = CreatePedidoDTO::fromRequest($request);
            $pedido = $this->pedidoService->create($dto);

            return response()->json([
                'success' => true,
                'message' => 'Pedido registrado exitosamente',
                'pedido'  => $pedido,
                'data'    => $pedido,
            ], 201);
        } catch (\Exception $e) {
            return $this->errorResponse(
                message: 'Error al crear el pedido: ' . $e->getMessage(),
                code: 500
            );
        }
    }

    public function storeWebhook(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'cliente_nombre'             => 'required|string',
            'cliente_telefono'           => 'required|string',
            'direccion'                  => 'nullable|string',
            'tipo_entrega'               => 'required|in:Domicilio,Recoger,Local',
            'nota'                       => 'nullable|string',
            'detalles'                   => 'required|array|min:1',
            'detalles.*.producto_id'     => 'required|exists:productos,id',
            'detalles.*.nombre_producto' => 'required|string',
            'detalles.*.cantidad'        => 'required|numeric|min:0.01',
            'detalles.*.precio_unitario' => 'required|numeric|min:0',
        ]);

        try {
            $pedido = $this->pedidoService->createFromWebhook($validated);

            return response()->json([
                'success' => true,
                'message' => 'Pedido registrado exitosamente desde webhook',
                'pedido'  => $pedido,
                'data'    => $pedido,
            ], 201);
        } catch (\Exception $e) {
            return $this->errorResponse(
                message: 'Error en webhook de pedido: ' . $e->getMessage(),
                code: 500
            );
        }
    }

    public function updateStatus(UpdatePedidoStatusRequest $request, int $id): JsonResponse
    {
        try {
            $pedido = $this->pedidoService->updateStatus($id, $request->validated('estado'));

            return response()->json([
                'success' => true,
                'message' => 'Estado actualizado a ' . $pedido->estado,
                'pedido'  => $pedido,
                'data'    => $pedido,
            ]);
        } catch (\Exception $e) {
            return $this->errorResponse(
                message: 'Error al actualizar el estado: ' . $e->getMessage(),
                code: 400
            );
        }
    }
}
