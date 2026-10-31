<?php

namespace App\Modules\Cliente\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Modules\Cliente\Services\ClienteService;
use App\Modules\Cliente\Http\Requests\StoreClienteRequest;
use App\Modules\Cliente\Http\Requests\UpdateClienteRequest;
use App\Modules\Cliente\Http\Resources\ClienteResource;
use Illuminate\Http\Request;

class ClienteController extends Controller
{
    protected $service;

    public function __construct(ClienteService $service)
    {
        $this->service = $service;
        $this->authorizeResource(\App\Modules\Cliente\Models\Cliente::class, 'cliente');
    }

    /**
     * Display a listing of the resource.
     */
    public function index(Request $request)
    {
        $perPage = $request->input('per_page', 15);
        $search = $request->input('search', null);

        $clientes = $this->service->getAllClientes($perPage, $search);

        return response()->json([
            'data' => ClienteResource::collection($clientes),
            'meta' => [
                'total' => $clientes->total(),
                'per_page' => $clientes->perPage(),
                'current_page' => $clientes->currentPage(),
                'last_page' => $clientes->lastPage(),
            ]
        ]);
    }

    /**
     * Store a newly created resource in storage.
     */
    public function store(StoreClienteRequest $request)
    {
        $cliente = $this->service->createCliente($request->validated());

        return response()->json([
            'message' => 'Cliente creado exitosamente',
            'data' => new ClienteResource($cliente)
        ], 201);
    }

    /**
     * Display the specified resource.
     */
    public function show($id)
    {
        $cliente = $this->service->getClienteById($id);

        return new ClienteResource($cliente);
    }

    /**
     * Update the specified resource in storage.
     */
    public function update(UpdateClienteRequest $request, $id)
    {
        $cliente = $this->service->updateCliente($id, $request->validated());

        return response()->json([
            'message' => 'Cliente actualizado exitosamente',
            'data' => new ClienteResource($cliente)
        ]);
    }

    /**
     * Remove the specified resource from storage.
     */
    public function destroy($id)
    {
        $this->service->deleteCliente($id);

        return response()->json([
            'message' => 'Cliente eliminado exitosamente'
        ]);
    }
}
