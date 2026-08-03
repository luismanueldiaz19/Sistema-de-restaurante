<?php

namespace Tests\Feature\Inventory;

use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;
use App\Models\Producto;
use App\Models\Receta;
use App\Models\MovimientoInventario;
use App\Services\InventoryService;

class ProcesarVentaTest extends TestCase
{
    use RefreshDatabase;

    public function test_debe_descontar_stock_de_producto_directo_al_procesar_venta()
    {
        // =============================================================
        // CASO DE NEGOCIO
        // =============================================================
        // El cliente compra un producto directo (ej. un Refresco).
        // Refresco inicial: Stock 20.
        // Se venden 5 unidades.
        // El sistema debe descontar 5 unidades del stock (quedan 15)
        // Y registrar un movimiento de salida con la referencia de la venta.
        // =============================================================

        // =============================================================
        // ARRANGE (Preparar el escenario)
        // =============================================================
        $refresco = Producto::factory()->create([
            'nombre' => 'Refresco',
            'tipo_producto' => 'PRODUCTO',
            'maneja_inventario' => true,
            'stock_actual' => 20
        ]);

        $inventoryService = new InventoryService();

        // =============================================================
        // ACT (Ejecutar la acción)
        // =============================================================
        $inventoryService->procesarVenta($refresco->id, 5, 'Factura-001');

        // =============================================================
        // ASSERT (Verificar el resultado)
        // =============================================================
        $refresco->refresh(); // Recargamos el producto de la BD para ver su nuevo stock

        // 1. Verificamos que el stock se descontó correctamente
        $this->assertEquals(15, $refresco->stock_actual);

        // 2. Verificamos que se creó el movimiento de inventario en la tabla
        $this->assertDatabaseHas('movimientos_inventario', [
            'producto_id' => $refresco->id,
            'tipo' => 'SALIDA',
            'cantidad' => 5,
            'referencia' => 'VENTA: Factura-001'
        ]);
    }

    public function test_debe_descontar_ingredientes_proporcionalmente_al_procesar_venta_de_un_plato()
    {
        // =============================================================
        // CASO DE NEGOCIO
        // =============================================================
        // El cliente compra un producto tipo PLATO (ej. Hamburguesa).
        // La Hamburguesa NO se descuenta a sí misma, descuenta sus ingredientes.
        // Ingredientes: 2 Panes (Stock inicial 50) y 1 Carne (Stock inicial 20).
        // Se venden 3 Hamburguesas.
        // El sistema debe descontar:
        // - 6 Panes (quedan 44)
        // - 3 Carnes (quedan 17)
        // Y registrar los movimientos para ambos ingredientes.
        // =============================================================

        // =============================================================
        // ARRANGE (Preparar el escenario)
        // =============================================================
        $hamburguesa = Producto::factory()->create([
            'nombre' => 'Hamburguesa',
            'tipo_producto' => 'PLATO'
        ]);

        $pan = Producto::factory()->materiaPrima()->create([
            'nombre' => 'Pan',
            'stock_actual' => 50
        ]);

        $carne = Producto::factory()->materiaPrima()->create([
            'nombre' => 'Carne',
            'stock_actual' => 20
        ]);

        Receta::factory()->create([
            'producto_id' => $hamburguesa->id,
            'ingrediente_producto_id' => $pan->id,
            'cantidad' => 2
        ]);

        Receta::factory()->create([
            'producto_id' => $hamburguesa->id,
            'ingrediente_producto_id' => $carne->id,
            'cantidad' => 1
        ]);

        $inventoryService = new InventoryService();

        // =============================================================
        // ACT (Ejecutar la acción)
        // =============================================================
        $inventoryService->procesarVenta($hamburguesa->id, 3, 'Factura-002');

        // =============================================================
        // ASSERT (Verificar el resultado)
        // =============================================================
        $pan->refresh();
        $carne->refresh();

        // 1. Verificamos el stock de los ingredientes
        $this->assertEquals(44, $pan->stock_actual);
        $this->assertEquals(17, $carne->stock_actual);

        // 2. Verificamos los movimientos de inventario de cada ingrediente
        $this->assertDatabaseHas('movimientos_inventario', [
            'producto_id' => $pan->id,
            'tipo' => 'SALIDA',
            'cantidad' => 6,
            'referencia' => 'VENTA: Factura-002'
        ]);

        $this->assertDatabaseHas('movimientos_inventario', [
            'producto_id' => $carne->id,
            'tipo' => 'SALIDA',
            'cantidad' => 3,
            'referencia' => 'VENTA: Factura-002'
        ]);
    }
}
