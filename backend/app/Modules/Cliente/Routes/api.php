<?php

use Illuminate\Support\Facades\Route;
use App\Modules\Cliente\Http\Controllers\Api\ClienteController;

/*
|--------------------------------------------------------------------------
| Rutas del Módulo Cliente
|--------------------------------------------------------------------------
| Estas rutas se registran dentro de api.php de la aplicación bajo un prefijo
| definido allá (ej. /api/v2).
*/

// Agregamos middleware sanctum para requerir token
Route::middleware(['auth:sanctum'])->group(function () {
    Route::apiResource('clientes', ClienteController::class);
});
