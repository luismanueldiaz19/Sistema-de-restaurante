<?php

declare(strict_types=1);

namespace App\Modules\Producto\Services;

use App\Models\Producto;
use App\Modules\Producto\DTOs\CreateProductoDTO;
use App\Modules\Producto\DTOs\UpdateProductoDTO;
use App\Modules\Producto\Exceptions\ProductoException;
use App\Modules\Producto\Repositories\Contracts\ProductoRepositoryInterface;
use Illuminate\Pagination\LengthAwarePaginator;
use Illuminate\Support\Facades\DB;
use Exception;

class ProductoService
{
    public function __construct(
        private readonly ProductoRepositoryInterface $productoRepository
    ) {}

    public function getAll(int $perPage = 15, array $filters = []): LengthAwarePaginator
    {
        return $this->productoRepository->getAll($perPage, $filters);
    }

    public function getById(int $id): Producto
    {
        return $this->productoRepository->findById($id);
    }

    public function create(CreateProductoDTO $dto): Producto
    {
        return DB::transaction(function () use ($dto) {
            try {
                return $this->productoRepository->create($dto->toArray());
            } catch (Exception $e) {
                throw new ProductoException("Error al crear el producto: " . $e->getMessage());
            }
        });
    }

    public function update(int $id, UpdateProductoDTO $dto): Producto
    {
        return DB::transaction(function () use ($id, $dto) {
            try {
                return $this->productoRepository->update($id, $dto->toArray());
            } catch (Exception $e) {
                throw new ProductoException("Error al actualizar el producto: " . $e->getMessage());
            }
        });
    }

    public function delete(int $id): bool
    {
        return DB::transaction(function () use ($id) {
            try {
                return $this->productoRepository->delete($id);
            } catch (Exception $e) {
                throw new ProductoException("Error al eliminar el producto: " . $e->getMessage());
            }
        });
    }
}
