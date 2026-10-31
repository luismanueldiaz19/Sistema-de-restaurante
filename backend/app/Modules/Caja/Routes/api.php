<?php

use Illuminate\Support\Facades\Route;
use App\Modules\Caja\Http\Controllers\CajaController;

Route::middleware(['auth:sanctum'])->prefix('cajas')->group(function () {
    Route::get('/', [CajaController::class, 'index']);
    Route::get('/turnos', [CajaController::class, 'turnos']);
    Route::get('/estado', [CajaController::class, 'estadoActual']);
    Route::post('/abrir', [CajaController::class, 'abrir']);
    Route::get('/resumen', [CajaController::class, 'resumen']);
    Route::post('/cerrar', [CajaController::class, 'cerrar']);
    Route::get('/historial', [CajaController::class, 'historial']);
});
