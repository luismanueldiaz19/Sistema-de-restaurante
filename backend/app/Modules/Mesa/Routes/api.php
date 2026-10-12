<?php

use Illuminate\Support\Facades\Route;
use App\Modules\Mesa\Http\Controllers\MesaController;

Route::middleware(['auth:sanctum'])->prefix('mesas')->group(function () {
    Route::get('/', [MesaController::class, 'index']);
    Route::post('/', [MesaController::class, 'store']);
    Route::get('/areas', [MesaController::class, 'areas']);
    Route::get('/{id}', [MesaController::class, 'show']);
    Route::put('/{id}', [MesaController::class, 'update']);
    Route::delete('/{id}', [MesaController::class, 'destroy']);

    Route::post('/{id}/abrir', [MesaController::class, 'abrir']);
    Route::post('/{id}/agregar-items', [MesaController::class, 'agregarItems']);
    Route::post('/{id}/solicitar-cuenta', [MesaController::class, 'solicitarCuenta']);
    Route::post('/{id}/liberar', [MesaController::class, 'liberar']);
});
