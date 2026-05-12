<?php

use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\ClienteController;
use App\Http\Controllers\Api\FacturaController;
use App\Http\Controllers\Api\NcfSecuenciaController;
use App\Http\Controllers\Api\CajaController;
use App\Http\Controllers\Api\ProductoController;
use App\Http\Controllers\Api\IngredienteController;
use App\Http\Controllers\Api\NominaController;
use App\Http\Controllers\Api\EmpleadoController;
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


Route::middleware('auth:sanctum')->post('/logout', [AuthController::class, 'logout']);


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

    Route::get('/facturas/reportes', [FacturaController::class, 'reportes'])
        ->middleware('permission:ver_facturas');

    Route::get('/facturas/{id}', [FacturaController::class, 'show'])
        ->middleware('permission:ver_facturas');

    Route::post('/facturas/{id}/pagar', [FacturaController::class, 'pagar'])
        ->middleware('permission:editar_facturas');



  // ================= COMPROBANTES FISCALES =================
 
     Route::get('/ncf-secuencias', [NcfSecuenciaController::class, 'index'])
        ->middleware('permission:crear_facturas');

      Route::get('/ncf-secuencias/{id}', [NcfSecuenciaController::class, 'show'])
        ->middleware('permission:crear_facturas');

    // ================= CAJA Y TURNOS =================
    Route::get('/cajas', [CajaController::class, 'index']);
    Route::get('/turnos', [CajaController::class, 'turnos']);
    Route::get('/caja/estado', [CajaController::class, 'estadoActual']);
    Route::post('/caja/abrir', [CajaController::class, 'abrir']);
    Route::get('/caja/resumen', [CajaController::class, 'resumen']);
    Route::post('/caja/cerrar', [CajaController::class, 'cerrar']);
    Route::get('/caja/historial', [CajaController::class, 'historial']);

    // ================= PRODUCTOS =================
    Route::get('/productos', [ProductoController::class, 'index'])
        ->middleware('permission:ver_productos');

    Route::get('/productos/{id}', [ProductoController::class, 'show'])
        ->middleware('permission:ver_productos');

    Route::post('/productos', [ProductoController::class, 'store'])
        ->middleware('permission:crear_productos');

    Route::put('/productos/{id}', [ProductoController::class, 'update'])
        ->middleware('permission:editar_productos');

    Route::delete('/productos/{id}', [ProductoController::class, 'destroy'])
        ->middleware('permission:eliminar_productos');

    // ================= INGREDIENTES =================
    Route::get('/ingredientes', [IngredienteController::class, 'index'])
        ->middleware('permission:ver_inventario');

    Route::post('/ingredientes', [IngredienteController::class, 'store'])
        ->middleware('permission:crear_inventario');

    Route::put('/ingredientes/{id}', [IngredienteController::class, 'update'])
        ->middleware('permission:crear_inventario');

    Route::delete('/ingredientes/{id}', [IngredienteController::class, 'destroy'])
        ->middleware('permission:crear_inventario');

    // ================= NÓMINA =================
    Route::get('/empleados', [NominaController::class, 'getEmpleados'])
        ->middleware('permission:ver_nomina');
    
    Route::get('/nominas', [NominaController::class, 'index'])
        ->middleware('permission:ver_nomina');
    
    Route::post('/nominas', [NominaController::class, 'store'])
        ->middleware('permission:ver_nomina');
    
    Route::patch('/nominas/{id}/status', [NominaController::class, 'updateStatus'])
        ->middleware('permission:ver_nomina');

    // ================= EMPLEADOS =================
    Route::get('/empleados/all', [EmpleadoController::class, 'index'])
        ->middleware('permission:ver_nomina');
    
    Route::post('/empleados', [EmpleadoController::class, 'store'])
        ->middleware('permission:ver_nomina');
    
    Route::put('/empleados/{id}', [EmpleadoController::class, 'update'])
        ->middleware('permission:ver_nomina');
    
    Route::patch('/empleados/{id}/toggle', [EmpleadoController::class, 'toggleStatus'])
        ->middleware('permission:ver_nomina');

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
