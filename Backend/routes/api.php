<?php

use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\ClienteController;
use App\Http\Controllers\Api\FacturaController;
use App\Http\Controllers\Api\NcfSecuenciaController;
use App\Http\Controllers\Api\CajaController;
use App\Http\Controllers\Api\ProductoController;
use App\Http\Controllers\Api\CotizacionController;
use App\Http\Controllers\Api\OrdenCompraController;
use App\Http\Controllers\Api\NominaController;
use App\Http\Controllers\Api\EmpleadoController;
use App\Http\Controllers\Api\ProveedorController;
use App\Http\Controllers\Api\CompraController;
use App\Http\Controllers\Api\CxpController;
use App\Http\Controllers\Api\CxcController;
use App\Http\Controllers\Api\DgiiController;
use App\Http\Controllers\Api\ReporteContableController;
use App\Http\Controllers\Api\AjusteInventarioController;
use App\Http\Controllers\Api\NotaCreditoController;
use App\Http\Controllers\Api\PedidoController;
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

Route::get('/notas-credito/{id}/pdf', [NotaCreditoController::class, 'pdf']);

Route::middleware('auth:sanctum')->post('/logout', [AuthController::class, 'logout']);

// Webhook para Chatbot (Sin Auth de usuario)
Route::post('/pedidos/bot', [PedidoController::class, 'storeWebhook']);
Route::get('/pedidos/bot/productos', [ProductoController::class, 'index']);


Route::middleware(['auth:sanctum', 'role:admin'])->group(function () {
    Route::get('/admin', function () {
        return 'Solo admin';
    });
});

Route::middleware(['auth:sanctum'])->group(function () {

    // Compras Module
    Route::apiResource('proveedores', ProveedorController::class);
    Route::apiResource('compras', CompraController::class)->except(['update', 'destroy']);
    Route::get('/cxp', [CxpController::class, 'index']);
    Route::post('/cxp/{id}/pagar', [CxpController::class, 'registrarPago']);
    Route::get('/cxp/pagos/historial', [CxpController::class, 'historialPagos']);

    Route::get('/cxc', [CxcController::class, 'index']);
    Route::post('/cxc/{id}/pagar', [CxcController::class, 'registrarPago']);
    Route::get('/cxc/pagos/historial', [CxcController::class, 'historialPagos']);

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

    Route::post('/facturas/{id}/nota-credito', [NotaCreditoController::class, 'store'])
        ->middleware('permission:editar_facturas');

    Route::get('/notas-credito', [NotaCreditoController::class, 'index'])
        ->middleware('permission:ver_facturas');




  // ================= COMPROBANTES FISCALES =================
 
     Route::get('/ncf-secuencias', [NcfSecuenciaController::class, 'index'])
        ->middleware('permission:crear_facturas');

      Route::get('/ncf-secuencias/{id}', [NcfSecuenciaController::class, 'show'])
        ->middleware('permission:crear_facturas');

    // ================= PEDIDOS =================
    Route::post('/pedidos', [PedidoController::class, 'store']);
    Route::get('/pedidos', [PedidoController::class, 'index']);
    Route::get('/pedidos/codigo/{codigo}', [PedidoController::class, 'getByCodigo']);
    Route::put('/pedidos/{id}/estado', [PedidoController::class, 'updateStatus']);

    // ================= ASIGNACIÓN DE MESAS Y CUENTAS =================
    Route::post('/cajas/{cajaId}/asignar-mesa', [CajaController::class, 'asignarMesa']);

    // ================= INVENTARIO =================
    Route::post('/inventario/ajuste', [AjusteInventarioController::class, 'store'])
        ->middleware('permission:ver_inventario');
    
    Route::get('/inventario/movimientos', [AjusteInventarioController::class, 'index'])
        ->middleware('permission:ver_inventario');

    // ================= CONTABILIDAD =================
    Route::get('/contabilidad/mayor-general', [ReporteContableController::class, 'mayorGeneral']);
    Route::get('/contabilidad/balance-general', [ReporteContableController::class, 'balanceGeneral']);
    Route::get('/contabilidad/estado-resultados', [ReporteContableController::class, 'estadoResultados']);

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

    Route::post('/productos/import', [ProductoController::class, 'import'])
        ->middleware('permission:crear_productos');

    Route::get('/productos/{id}', [ProductoController::class, 'show'])
        ->middleware('permission:ver_productos');

    Route::post('/productos', [ProductoController::class, 'store'])
        ->middleware('permission:crear_productos');

    Route::put('/productos/{id}', [ProductoController::class, 'update'])
        ->middleware('permission:editar_productos');

    Route::delete('/productos/{id}', [ProductoController::class, 'destroy'])
        ->middleware('permission:eliminar_productos');

    // ================= INGREDIENTES (Eliminados, unificados en Productos) =================
    Route::get('/recetas', [\App\Http\Controllers\Api\RecetaController::class, 'index'])
        ->middleware('permission:gestionar_recetas');
    Route::get('/recetas/{id}', [\App\Http\Controllers\Api\RecetaController::class, 'show'])
        ->middleware('permission:gestionar_recetas');
    Route::put('/recetas/{id}', [\App\Http\Controllers\Api\RecetaController::class, 'update'])
        ->middleware('permission:gestionar_recetas');

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

    // ================= CONTABILIDAD =================
    Route::get('/catalogo-cuentas', [\App\Http\Controllers\Api\CatalogoCuentaController::class, 'index']);
    Route::get('/configuracion-contable', [\App\Http\Controllers\Api\ConfiguracionContableController::class, 'index']);
    Route::put('/configuracion-contable/{id}', [\App\Http\Controllers\Api\ConfiguracionContableController::class, 'update']);
    Route::post('/configuracion-contable/bulk', [\App\Http\Controllers\Api\ConfiguracionContableController::class, 'bulkUpdate']);
    Route::get('/asientos', [\App\Http\Controllers\Api\AsientoContableController::class, 'index']);

    // ================= CATÁLOGOS PRODUCTOS =================
    Route::apiResource('categorias', \App\Http\Controllers\Api\CategoriaController::class)->middleware('permission:ver_inventario');
    Route::apiResource('marcas', \App\Http\Controllers\Api\MarcaController::class)->middleware('permission:ver_inventario');
    Route::apiResource('unidades-medida', \App\Http\Controllers\Api\UnidadMedidaController::class)->middleware('permission:ver_inventario');
    Route::apiResource('impuestos', \App\Http\Controllers\Api\ImpuestoController::class)->middleware('permission:ver_inventario');

    // ================= DGII / IMPUESTOS =================
    Route::get('/dgii/balance', [DgiiController::class, 'getBalance']);
    Route::get('/dgii/pagos', [DgiiController::class, 'getPagos']);
    Route::post('/dgii/pagar', [DgiiController::class, 'registrarPago']);
    Route::get('/dgii/preview-606', [DgiiController::class, 'preview606']);
    Route::get('/dgii/preview-607', [DgiiController::class, 'preview607']);
    Route::get('/dgii/exportar-606', [DgiiController::class, 'exportar606']);
    Route::get('/dgii/exportar-607', [DgiiController::class, 'exportar607']);

    // ================= COTIZACIONES =================
    Route::apiResource('cotizaciones', \App\Http\Controllers\Api\CotizacionController::class);
    Route::patch('cotizaciones/{id}/estado', [\App\Http\Controllers\Api\CotizacionController::class, 'updateStatus']);
    Route::get('cotizaciones/{id}/pdf', [\App\Http\Controllers\Api\CotizacionController::class, 'pdf']);

    // ================= ORDENES DE COMPRA =================
    Route::apiResource('ordenes-compras', \App\Http\Controllers\Api\OrdenCompraController::class);
    Route::patch('ordenes-compras/{id}/estado', [\App\Http\Controllers\Api\OrdenCompraController::class, 'updateStatus']);
    Route::get('ordenes-compras/{id}/pdf', [\App\Http\Controllers\Api\OrdenCompraController::class, 'generatePdf']);

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
