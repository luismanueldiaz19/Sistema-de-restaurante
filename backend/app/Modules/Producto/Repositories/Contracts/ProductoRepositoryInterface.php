<?php

declare(strict_types=1);

namespace App\Modules\Producto\Repositories\Contracts;

use App\Models\Producto;
use Illuminate\Pagination\LengthAwarePaginator;

interface ProductoRepositoryInterface
{
    public function getAll(int $perPage = 15, array $filters = []): LengthAwarePaginator;
    public function findById(int $id): Producto;
    public function create(array $data): Producto;
    public function update(int $id, array $data): Producto;
    public function delete(int $id): bool;
}
