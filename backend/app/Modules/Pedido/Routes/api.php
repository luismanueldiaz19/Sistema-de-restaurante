<?php

use Illuminate\Support\Facades\Route;
use App\Modules\Pedido\Http\Controllers\PedidoController;

Route::middleware(['auth:sanctum'])->prefix('pedidos')->group(function () {
    Route::get('/', [PedidoController::class, 'index']);
    Route::post('/', [PedidoController::class, 'store']);
    Route::get('/codigo/{codigo}', [PedidoController::class, 'getByCodigo']);
    Route::get('/{id}', [PedidoController::class, 'show']);
    Route::put('/{id}/estado', [PedidoController::class, 'updateStatus']);
    Route::patch('/{id}/estado', [PedidoController::class, 'updateStatus']);
});

Route::post('/pedidos/bot', [PedidoController::class, 'storeWebhook']);
