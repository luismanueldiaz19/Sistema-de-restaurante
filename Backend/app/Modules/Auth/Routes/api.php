<?php

use Illuminate\Support\Facades\Route;
use App\Modules\Auth\Http\Controllers\AuthController;

/*
|--------------------------------------------------------------------------
| Rutas del Módulo Auth v2
|--------------------------------------------------------------------------
*/

// Generar Token
Route::post('login', [AuthController::class, 'login']);

// Revocar Token (requiere estar autenticado con el token actual)
Route::middleware(['auth:sanctum'])->group(function () {
    Route::post('logout', [AuthController::class, 'logout']);
});
