<?php

namespace App\Modules\Cliente\Services;

use App\Modules\Cliente\Repositories\ClienteRepository;
use Illuminate\Support\Facades\DB;
use Exception;

class ClienteService
{
    protected $repository;

    public function __construct(ClienteRepository $repository)
    {
        $this->repository = $repository;
    }

    public function getAllClientes($perPage = 15, $search = null)
    {
        return $this->repository->getAll($perPage, $search);
    }

    public function getClienteById($id)
    {
        return $this->repository->findById($id);
    }

    public function createCliente(array $data)
    {
        DB::beginTransaction();
        try {
            // Aquí podemos agregar lógica de negocio adicional (e.g. enviar email de bienvenida)
            $cliente = $this->repository->create($data);     
            DB::commit();
            return $cliente;
        } catch (Exception $e) {
            DB::rollBack();
            throw $e;
        }
    }

    public function updateCliente($id, array $data) {
        DB::beginTransaction();
        try {
            // Validaciones extras de negocio antes de actualizar
            $cliente = $this->repository->update($id, $data);
            
            DB::commit();
            return $cliente;
        } catch (Exception $e) {
            DB::rollBack();
            throw $e;
        }
    }

    public function deleteCliente($id)
    {
        DB::beginTransaction();
        try {
            // Verificar si el cliente tiene facturas u otras dependencias antes de eliminar
            // Si las tiene, podríamos lanzar una excepción o desactivar en lugar de eliminar
            
            $deleted = $this->repository->delete($id);
            
            DB::commit();
            return $deleted;
        } catch (Exception $e) {
            DB::rollBack();
            throw $e;
        }
    }
}
