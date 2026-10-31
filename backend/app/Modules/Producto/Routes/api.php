<?php

declare(strict_types=1);

namespace App\Modules\Producto\Routes;

use Illuminate\Support\Facades\Route;
use App\Modules\Producto\Http\Controllers\ProductoController;

Route::middleware(['auth:sanctum'])->group(function () {
    Route::get('productos-compras', [ProductoController::class, 'paraCompras']);
    Route::get('productos/template', [ProductoController::class, 'downloadTemplate']);
    Route::post('productos/import/preview', [ProductoController::class, 'previewImport']);
    Route::post('productos/import/confirm', [ProductoController::class, 'confirmImport']);
    Route::post('productos/import', [ProductoController::class, 'import']);
    Route::apiResource('productos', ProductoController::class);
});
