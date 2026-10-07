<?php

use Illuminate\Support\Facades\Route;
use App\Modules\Caja\Http\Controllers\CajaController;

Route::middleware(['auth:sanctum'])->prefix('cajas')->group(function () {
    Route::post('/abrir', [CajaController::class, 'abrir']);
});
