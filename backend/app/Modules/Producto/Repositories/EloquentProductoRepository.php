<?php

declare(strict_types=1);

namespace App\Modules\Producto\Repositories;

use App\Models\Producto;
use App\Modules\Producto\Repositories\Contracts\ProductoRepositoryInterface;
use Illuminate\Pagination\LengthAwarePaginator;

class EloquentProductoRepository implements ProductoRepositoryInterface
{
    public function getAll(int $perPage = 15, array $filters = []): LengthAwarePaginator
    {
        $query = Producto::query()->with(['categoria', 'marca', 'unidadMedida', 'impuesto']);

        if (!empty($filters['categoria_id'])) {
            $query->where('categoria_id', $filters['categoria_id']);
        }

        if (!empty($filters['marca_id'])) {
            $query->where('marca_id', $filters['marca_id']);
        }

        if (!empty($filters['tipo_producto'])) {
            if (is_array($filters['tipo_producto'])) {
                $query->whereIn('tipo_producto', $filters['tipo_producto']);
            } else {
                $query->where('tipo_producto', $filters['tipo_producto']);
            }
        }

        if (!empty($filters['exclude_tipo_producto'])) {
            if (is_array($filters['exclude_tipo_producto'])) {
                $query->whereNotIn('tipo_producto', $filters['exclude_tipo_producto']);
            } else {
                $query->where('tipo_producto', '!=', $filters['exclude_tipo_producto']);
            }
        }

        if (!empty($filters['search'])) {
            $search = strtolower($filters['search']);
            $query->where(function($q) use ($search) {
                $q->whereRaw('LOWER(nombre) LIKE ?', ["%{$search}%"])
                  ->orWhereRaw('LOWER(codigo) LIKE ?', ["%{$search}%"])
                  ->orWhereHas('categoria', function ($q2) use ($search) {
                      $q2->whereRaw('LOWER(nombre) LIKE ?', ["%{$search}%"]);
                  });
            });
        }

        return $query->latest()->paginate($perPage);
    }

    public function findById(int $id): Producto
    {
        return Producto::findOrFail($id);
    }

    public function create(array $data): Producto
    {
        return Producto::create($data);
    }

    public function update(int $id, array $data): Producto
    {
        $producto = $this->findById($id);
        $producto->update($data);

        return $producto;
    }

    public function delete(int $id): bool
    {
        $producto = $this->findById($id);
        return $producto->delete();
    }
}
