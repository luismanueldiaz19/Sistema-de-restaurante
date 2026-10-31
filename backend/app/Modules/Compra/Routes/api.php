<?php

declare(strict_types=1);

use Illuminate\Support\Facades\Route;
use App\Modules\Compra\Http\Controllers\CompraController;

Route::middleware(['auth:sanctum'])->group(function () {
    Route::get('/compras', [CompraController::class, 'index']);
    Route::post('/compras', [CompraController::class, 'store']);
    Route::get('/compras/reporte/pdf', [CompraController::class, 'pdfReporte']);
    Route::get('/compras/reporte/pdf-token', [CompraController::class, 'generarTokenReporte']);
    Route::get('/compras/{id}', [CompraController::class, 'show']);
    Route::get('/compras/{id}/pdf', [CompraController::class, 'pdf']);
    Route::get('/compras/{id}/pdf-token', [CompraController::class, 'generarTokenCompra']);
});
