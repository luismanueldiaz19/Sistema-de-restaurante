<?php

declare(strict_types=1);

namespace App\Modules\Producto\Providers;

use Illuminate\Support\ServiceProvider;
use App\Modules\Producto\Repositories\Contracts\ProductoRepositoryInterface;
use App\Modules\Producto\Repositories\EloquentProductoRepository;

class ProductoServiceProvider extends ServiceProvider
{
    public function register(): void
    {
        $this->app->bind(ProductoRepositoryInterface::class, EloquentProductoRepository::class);
    }

    public function boot(): void
    {
        //
    }
}
