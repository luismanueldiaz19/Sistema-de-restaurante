<?php

use App\Modules\Ecf\Http\Controllers\DgiiMockController;
use App\Modules\Ecf\Http\Controllers\EcfController;
use Illuminate\Support\Facades\Route;

// ──────────────────────────────────────────────────────────────────────────────
// SIMULADOR LOCAL (MOCK SERVER) API DGII (Público/Bearer DGII propio)
// ──────────────────────────────────────────────────────────────────────────────
Route::prefix('dgii-mock')->group(function () {
    Route::get('/autenticacion/api/semilla', [DgiiMockController::class, 'semilla']);
    Route::get('/autenticacion/api/Autenticacion/Semilla', [DgiiMockController::class, 'semilla']);

    Route::post('/autenticacion/api/validacion', [DgiiMockController::class, 'validarSemilla']);
    Route::post('/autenticacion/api/validacioncertificado', [DgiiMockController::class, 'validarSemilla']);
    Route::post('/autenticacion/api/Autenticacion/ValidarSemilla', [DgiiMockController::class, 'validarSemilla']);

    Route::post('/recepcion/api/ecf', [DgiiMockController::class, 'recepcionEcf']);
    Route::post('/recepcion/api/facturaselectronicas', [DgiiMockController::class, 'recepcionEcf']);
    Route::post('/recepcion/api/FacturasElectronicas', [DgiiMockController::class, 'recepcionEcf']);

    Route::post('/recepcionfc/api/recepcion', [DgiiMockController::class, 'recepcionRfce']);
    Route::post('/recepcionfc/api/Recepcion/ecf', [DgiiMockController::class, 'recepcionRfce']);

    Route::get('/consultaresultado/api/consultas/estado', [DgiiMockController::class, 'consultarEstado']);
    Route::get('/consultaresultado/api/Consultas/Estado', [DgiiMockController::class, 'consultarEstado']);
});

// ──────────────────────────────────────────────────────────────────────────────
// GESTIÓN Y MONITOREO DEL MÓDULO EMISOR e-CF (Protegido con Sanctum)
// ──────────────────────────────────────────────────────────────────────────────
Route::middleware(['auth:sanctum'])->prefix('ecf')->group(function () {
    Route::get('/estado-sistema', [EcfController::class, 'estadoSistema']);
    Route::put('/configuracion', [EcfController::class, 'actualizarConfiguracion']);
    Route::post('/certificado/generar-prueba', [EcfController::class, 'generarCertificadoPrueba']);
    Route::post('/certificado/upload', [EcfController::class, 'subirCertificado']);
    Route::post('/probar-conexion', [EcfController::class, 'probarConexion']);

    Route::get('/documentos', [EcfController::class, 'listarDocumentos']);
    Route::get('/documentos/{id}', [EcfController::class, 'verDocumento']);
    Route::get('/documentos/{id}/xml', [EcfController::class, 'descargarXml']);
    Route::post('/documentos/{id}/reenviar', [EcfController::class, 'reenviar']);
    Route::get('/documentos/{id}/consultar-estado', [EcfController::class, 'consultarEstado']);
    Route::post('/emitir-factura/{facturaId}', [EcfController::class, 'emitirPorFactura']);
});

