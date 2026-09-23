<?php

namespace App\Modules\Cliente\Repositories;

use App\Modules\Cliente\Models\Cliente;

class ClienteRepository
{
    /**
     * Get all clients with optional pagination and filtering.
     */
    public function getAll($perPage = 15, $search = null)
    {
        $query = Cliente::query();

        if ($search) {
            $searchLower = strtolower($search);
            $query->whereRaw('LOWER(nombre) LIKE ?', ["%{$searchLower}%"])
                  ->orWhereRaw('LOWER(rnc_cedula) LIKE ?', ["%{$searchLower}%"])
                  ->orWhereRaw('LOWER(email) LIKE ?', ["%{$searchLower}%"]);
        }

        return $query->latest()->paginate($perPage);
    }

    /**
     * Find a client by ID.
     */
    public function findById($id)
    {
        return Cliente::findOrFail($id);
    }

    /**
     * Create a new client.
     */
    public function create(array $data)
    {
        return Cliente::create($data);
    }

    /**
     * Update an existing client.
     */
    public function update($id, array $data)
    {
        $cliente = $this->findById($id);
        $cliente->update($data);

        return $cliente;
    }

    /**
     * Delete (or soft delete) a client.
     */
    public function delete($id)
    {
        $cliente = $this->findById($id);
        return $cliente->delete();
    }
}
