<?php

use Illuminate\Support\Facades\Route;
use App\Modules\CuentaPorPagar\Http\Controllers\CuentaPorPagarController;

Route::middleware(['auth:sanctum'])->group(function () {
    Route::get('/cxp', [CuentaPorPagarController::class, 'index']);
    Route::get('/cxp/pagos/historial', [CuentaPorPagarController::class, 'historialPagos']);
    Route::post('/cxp/{id}/pagar', [CuentaPorPagarController::class, 'registrarPago']);
});
