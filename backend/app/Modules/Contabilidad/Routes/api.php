<?php

declare(strict_types=1);

use Illuminate\Support\Facades\Route;
use App\Modules\Contabilidad\Http\Controllers\ConfiguracionContableController;
use App\Modules\Contabilidad\Http\Controllers\AsientoContableController;
use App\Modules\Contabilidad\Http\Controllers\CatalogoCuentaController;
use App\Modules\Contabilidad\Http\Controllers\ReporteContableController;

Route::middleware(['auth:sanctum'])->group(function () {
    // ⚙️ Motor de Configuración Contable Automática
    Route::get('/configuracion-contable', [ConfiguracionContableController::class, 'index']);
    Route::put('/configuracion-contable/{id}', [ConfiguracionContableController::class, 'update']);
    Route::post('/configuracion-contable/bulk', [ConfiguracionContableController::class, 'bulkUpdate']);

    // 📒 Asientos Contables
    Route::get('/asientos', [AsientoContableController::class, 'index']);
    Route::post('/asientos/manual', [AsientoContableController::class, 'store']);

    // 📊 Catálogo de Cuentas y Reportes Financieros
    Route::apiResource('catalogo-cuentas', CatalogoCuentaController::class);
    Route::get('/contabilidad/libro-diario', [ReporteContableController::class, 'libroDiario']);
    Route::get('/contabilidad/mayor-general', [ReporteContableController::class, 'mayorGeneral']);
    Route::get('/contabilidad/balance-general', [ReporteContableController::class, 'balanceGeneral']);
    Route::get('/contabilidad/estado-resultados', [ReporteContableController::class, 'estadoResultados']);
});
