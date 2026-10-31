<?php

use Illuminate\Support\Facades\Route;
use App\Modules\Cotizacion\Http\Controllers\CotizacionController;

Route::middleware(['auth:sanctum'])->prefix('cotizaciones')->group(function () {
    Route::post('/', [CotizacionController::class, 'store']);
    Route::get('/', [CotizacionController::class, 'index']);
    Route::get('/{id}', [CotizacionController::class, 'show']);
    Route::patch('/{id}/estado', [CotizacionController::class, 'updateStatus']);
});


