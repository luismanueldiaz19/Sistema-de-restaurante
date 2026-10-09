<?php

use Illuminate\Support\Facades\Route;
use App\Modules\Pago\Http\Controllers\PagoController;

Route::middleware(['auth:sanctum'])->group(function () {
    Route::post('/pagos/facturas/{factura_id}', [PagoController::class, 'registrarPago']);
});
