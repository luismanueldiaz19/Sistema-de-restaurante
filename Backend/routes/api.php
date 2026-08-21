<?php

use App\Http\Controllers\Api\Auth\AuthController;
use App\Http\Controllers\Api\Facturacion\ClienteController;
use App\Http\Controllers\Api\Facturacion\FacturaController;
use App\Http\Controllers\Api\Facturacion\NcfSecuenciaController;
use App\Http\Controllers\Api\Finanzas\CajaController;
use App\Http\Controllers\Api\Inventario\ProductoController;
use App\Http\Controllers\Api\Facturacion\CotizacionController;
use App\Http\Controllers\Api\Compras\OrdenCompraController;
use App\Http\Controllers\Api\RRHH\NominaController;
use App\Http\Controllers\Api\RRHH\EmpleadoController;
use App\Http\Controllers\Api\Compras\ProveedorController;
use App\Http\Controllers\Api\Compras\CompraController;
use App\Http\Controllers\Api\Finanzas\CxpController;
use App\Http\Controllers\Api\Finanzas\CxcController;
use App\Http\Controllers\Api\Impuestos\DgiiController;
use App\Http\Controllers\Api\Contabilidad\ReporteContableController;
use App\Http\Controllers\Api\Inventario\AjusteInventarioController;
use App\Http\Controllers\Api\Facturacion\NotaCreditoController;
use App\Http\Controllers\Api\Restaurante\PedidoController;
use App\Http\Controllers\Api\Inventario\RecetaController;
use App\Http\Controllers\Api\Contabilidad\CatalogoCuentaController;
use App\Http\Controllers\Api\Contabilidad\ConfiguracionContableController;
use App\Http\Controllers\Api\Contabilidad\AsientoContableController;
use App\Http\Controllers\Api\Inventario\CategoriaController;
use App\Http\Controllers\Api\Inventario\MarcaController;
use App\Http\Controllers\Api\Inventario\UnidadMedidaController;
use App\Http\Controllers\Api\Impuestos\ImpuestoController;
use App\Http\Controllers\Api\Finanzas\BankController;
use App\Http\Controllers\Api\Finanzas\BankAccountController;
use App\Http\Controllers\Api\Finanzas\BankTransactionController;
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
Route::get('/cotizaciones/{id}/pdf', [CotizacionController::class, 'pdf']);

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
    Route::get('/recetas', [RecetaController::class, 'index'])
        ->middleware('permission:gestionar_recetas');
    Route::get('/recetas/{id}', [RecetaController::class, 'show'])
        ->middleware('permission:gestionar_recetas');
    Route::put('/recetas/{id}', [RecetaController::class, 'update'])
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
    Route::apiResource('catalogo-cuentas', CatalogoCuentaController::class);
    Route::get('/configuracion-contable', [ConfiguracionContableController::class, 'index']);
    Route::put('/configuracion-contable/{id}', [ConfiguracionContableController::class, 'update']);
    Route::post('/configuracion-contable/bulk', [ConfiguracionContableController::class, 'bulkUpdate']);
    Route::get('/asientos', [AsientoContableController::class, 'index']);

    // ================= METODOS DE PAGO =================
    Route::get('/metodos-pagos/activos', [\App\Http\Controllers\Api\Finanzas\MetodoPagoController::class, 'activos']);
    Route::apiResource('metodos-pagos', \App\Http\Controllers\Api\Finanzas\MetodoPagoController::class);

    // ================= CATÁLOGOS PRODUCTOS =================
    Route::apiResource('categorias', CategoriaController::class)->middleware('permission:ver_inventario');
    Route::apiResource('marcas', MarcaController::class)->middleware('permission:ver_inventario');
    Route::apiResource('unidades-medida', UnidadMedidaController::class)->middleware('permission:ver_inventario');
    Route::apiResource('impuestos', ImpuestoController::class)->middleware('permission:ver_inventario');

    // ================= DGII / IMPUESTOS =================
    Route::get('/dgii/balance', [DgiiController::class, 'getBalance']);
    Route::get('/dgii/pagos', [DgiiController::class, 'getPagos']);
    Route::post('/dgii/pagar', [DgiiController::class, 'registrarPago']);
    Route::get('/dgii/preview-606', [DgiiController::class, 'preview606']);
    Route::get('/dgii/preview-607', [DgiiController::class, 'preview607']);
    Route::get('/dgii/exportar-606', [DgiiController::class, 'exportar606']);
    Route::get('/dgii/exportar-607', [DgiiController::class, 'exportar607']);

    // ================= COTIZACIONES =================
    Route::apiResource('cotizaciones', CotizacionController::class);
    Route::patch('cotizaciones/{id}/estado', [CotizacionController::class, 'updateStatus']);

    // ================= ORDENES DE COMPRA =================
    Route::apiResource('ordenes-compras', OrdenCompraController::class);
    Route::patch('ordenes-compras/{id}/estado', [OrdenCompraController::class, 'updateStatus']);
    Route::get('ordenes-compras/{id}/pdf', [OrdenCompraController::class, 'generatePdf']);

    // ================= FINANZAS / BANCOS =================
    Route::apiResource('bancos', BankController::class);
    Route::apiResource('cuentas-bancarias', BankAccountController::class);
    Route::post('transacciones-bancarias/conciliar', [BankTransactionController::class, 'reconcile']);
    Route::apiResource('transacciones-bancarias', BankTransactionController::class)->only(['index', 'store']);

});

