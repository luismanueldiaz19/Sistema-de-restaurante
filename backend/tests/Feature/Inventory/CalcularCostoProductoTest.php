<?php

namespace Tests\Feature\Inventory;

use Illuminate\Foundation\Testing\RefreshDatabase;  /// Por eso casi todos los Feature Tests empiezan así:
use Illuminate\Foundation\Testing\WithFaker;
use Tests\TestCase;

use App\Models\Producto;
use App\Services\InventoryService;
use App\Models\Receta;



class CalcularCostoProductoTest extends TestCase {

 use RefreshDatabase;

 public function test_debe_devolver_el_costo_de_un_producto() {
    // Arrange
    
     $producto = Producto::factory()->create(['costo' => 250]);  // crear producto
    
     $inventoryService = new InventoryService();   //  crear servicio
    // Act

    $resultado = $inventoryService -> calcularCostoProducto($producto->id);
    // Assert
    
    $this->assertEquals(250, $resultado);
   
}


public function test_debe_devolver_el_costo_de_un_producto_con_plato() {
    // =============================================================
    // CASO DE NEGOCIO
    // =============================================================
    // El cliente compra una Pizza.
    // La Pizza tiene:
    // 2 Harinas   (RD$50)
    // 3 Quesos    (RD$100)
    // El sistema debe calcular: (2 x 50) + (3 x 100)
    // Resultado esperado: RD$400
    // =============================================================

    // =============================================================
    // ARRANGE (Preparar el escenario de la prueba)
    // =============================================================
    
    // 1. Creamos el producto que será vendido (PLATO)
    $pizza = Producto::factory()->create([
        'nombre' => 'Pizza Personal',
        'tipo_producto' => 'PLATO',
    ]);

    // 2. Creamos los ingredientes con sus costos
    $harina = Producto::factory()->materiaPrima()->create([
        'nombre' => 'Harina',
        'costo' => 50
    ]);

    $queso = Producto::factory()->materiaPrima()->create([
        'nombre' => 'Queso',
        'costo' => 100
    ]);

    // 3. Creamos la receta asignando los ingredientes y cantidades a la pizza
    Receta::factory()->create([
        'producto_id' => $pizza->id,
        'ingrediente_producto_id' => $harina->id,
        'cantidad' => 2,
    ]);

    Receta::factory()->create([
        'producto_id' => $pizza->id,
        'ingrediente_producto_id' => $queso->id,
        'cantidad' => 3,
    ]);
    
    // 4. Creamos la clase que contiene la lógica a probar
    $inventoryService = new InventoryService();

    // =============================================================
    // ACT (Ejecutar la acción)
    // =============================================================
    
    // Ejecutamos el método que queremos probar enviando el ID de la Pizza
    $resultado = $inventoryService->calcularCostoProducto($pizza->id);
    
    // =============================================================
    // ASSERT (Verificar el resultado)
    // =============================================================
    
    // Esperamos que el costo obtenido sea exactamente 400
    // Si la lógica en InventoryService cambia por error, esta prueba fallará
    $this->assertEquals(400, $resultado);
}

}
