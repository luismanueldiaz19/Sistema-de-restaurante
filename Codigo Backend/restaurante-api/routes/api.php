<?php

use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\ClienteController;
use App\Http\Controllers\Api\FacturaController;

use Illuminate\Support\Facades\Route;

/*
|--------------------------------------------------------------------------
| API Routes
|--------------------------------------------------------------------------
|
| Here is where you can register API routes for your application. These
| routes are loaded by the RouteServiceProvider within a group which
| is assigned the "api" middleware group. Enjoy building your API!
|
*/

// públicas
Route::post('/register', [AuthController::class, 'register']);
Route::post('/login', [AuthController::class, 'login']);


Route::middleware(['auth:sanctum', 'role:admin'])->group(function () {
    Route::get('/admin', function () {
        return 'Solo admin';
    });
});

Route::middleware(['auth:sanctum'])->group(function () {

    Route::get('/clientes', [ClienteController::class, 'index'])
        ->middleware('permission:ver_clientes');

    // Route::post('/clientes', [ClienteController::class, 'store'])
    //     ->middleware('permission:crear_clientes');

 Route::post('/clientes', [ClienteController::class, 'store'])
        ->middleware('permission:crear_clientes');

    Route::get('/clientes/{id}', [ClienteController::class, 'show'])
        ->middleware('permission:ver_clientes');

    Route::put('/clientes/{id}', [ClienteController::class, 'update'])
        ->middleware('permission:editar_clientes');

    Route::delete('/clientes/{id}', [ClienteController::class, 'destroy'])
        ->middleware('permission:eliminar_clientes');

    // ================= FACTURAS =================

    Route::post('/facturas', [FacturaController::class, 'store'])
        ->middleware('permission:crear_facturas');

    Route::get('/facturas', [FacturaController::class, 'index'])
        ->middleware('permission:ver_facturas');

    Route::get('/facturas/{id}', [FacturaController::class, 'show'])
        ->middleware('permission:ver_facturas');

    Route::post('/facturas/{id}/pagar', [FacturaController::class, 'pagar'])
        ->middleware('permission:editar_facturas');

});

// // Route::post('/facturas', [FacturaController::class, 'store'])
// //     ->middleware('permission:crear_facturas');

// Route::post('/facturas', [FacturaController::class, 'store'])
//     ->middleware(['auth:sanctum', 'permission:crear_facturas']);

// Route::get('/facturas', [FacturaController::class, 'index'])
//     ->middleware(['auth:sanctum', 'permission:ver_facturas']);

// Route::post('/facturas/{id}/pagar', [FacturaController::class, 'pagar'])
//     ->middleware(['auth:sanctum', 'permission:editar_facturas']);

// Route::get('/facturas/{id}', [FacturaController::class, 'show'])
//     ->middleware(['auth:sanctum', 'permission:ver_facturas']);
