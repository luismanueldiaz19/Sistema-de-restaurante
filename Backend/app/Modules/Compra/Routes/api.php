<?php

declare(strict_types=1);

use Illuminate\Support\Facades\Route;
use App\Modules\Compra\Http\Controllers\CompraController;

Route::middleware(['auth:sanctum'])->group(function () {
    Route::get('/compras', [CompraController::class, 'index']);
    Route::post('/compras', [CompraController::class, 'store']);
    Route::get('/compras/{id}', [CompraController::class, 'show']);
});
