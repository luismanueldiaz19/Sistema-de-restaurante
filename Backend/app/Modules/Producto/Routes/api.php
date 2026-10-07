<?php

declare(strict_types=1);

namespace App\Modules\Producto\Routes;

use Illuminate\Support\Facades\Route;
use App\Modules\Producto\Http\Controllers\ProductoController;

Route::middleware(['auth:sanctum'])->group(function () {
    Route::post('productos/import', [ProductoController::class, 'import']);
    Route::apiResource('productos', ProductoController::class);
});
