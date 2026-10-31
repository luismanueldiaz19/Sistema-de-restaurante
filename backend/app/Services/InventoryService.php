<?php

namespace App\Services;

use App\Modules\Inventario\Services\InventarioService;
use App\Modules\Inventario\Services\RecetaService;

/**
 * Legacy InventoryService adapter.
 * Delegates to the modularized App\Modules\Inventario services.
 */
class InventoryService
{
    private InventarioService $inventarioService;
    private RecetaService $recetaService;

    public function __construct(
        ?InventarioService $inventarioService = null,
        ?RecetaService $recetaService = null
    ) {
        $this->inventarioService = $inventarioService ?? app(InventarioService::class);
        $this->recetaService = $recetaService ?? app(RecetaService::class);
    }

    /**
     * Procesar el descuento de inventario para una venta
     */
    public function procesarVenta(int $productoId, float $cantidadVenta, string $referencia = ''): void
    {
        $this->inventarioService->procesarSalidaVenta($productoId, $cantidadVenta, $referencia);
    }

    /**
     * Calcular costo de un producto basado en su receta
     */
    public function calcularCostoProducto(int $productoId): float
    {
        return $this->recetaService->calcularCostoProducto($productoId);
    }
}
