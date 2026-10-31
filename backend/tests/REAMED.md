/******************************************************************
 * MÓDULO:
 * Inventario
 *
 * CASO DE USO:
 * Calcular costo de un producto.
 *
 * ESCENARIO:
 * Producto tipo PLATO.
 *
 * REGLA DE NEGOCIO:
 * El costo del plato es la suma del costo de cada ingrediente
 * multiplicado por la cantidad definida en la receta.
 *
 * RESULTADO ESPERADO:
 * 2 Harinas (50) + 3 Quesos (100) = RD$400
 *
 * AUTOR:
 * Luis Manuel Díaz / Lwader Soft
 ******************************************************************/



 // =============================================================
// ARRANGE (Preparar el escenario de la prueba)
// =============================================================

// Creamos el producto que será vendido.
// En este caso NO es un PLATO, por lo tanto el método
// simplemente debe devolver el valor del campo "costo".
$producto = Producto::factory()->create([
    'nombre' => 'Kola Real',
    'tipo_producto' => 'PRODUCTO',
    'costo' => 150,
]);

// Creamos la clase que contiene la lógica del inventario.
// Esta será la clase que queremos probar.
$inventoryService = new InventoryService();



// =============================================================
// ACT (Ejecutar la acción)
// =============================================================

// Ejecutamos el método que queremos probar.
// Solo enviamos el ID del producto porque así fue diseñado
// el método calcularCostoProducto().
$resultado = $inventoryService->calcularCostoProducto($producto->id);



// =============================================================
// ASSERT (Verificar el resultado)
// =============================================================

// Esperamos que el costo obtenido sea exactamente 150.
// Si alguien modifica la lógica y devuelve otro valor,
// esta prueba fallará automáticamente.
$this->assertEquals(150, $resultado);



// =============================================================
// CASO DE NEGOCIO
// =============================================================
//
// El cliente compra una Pizza.
//
// La Pizza tiene:
//
// 2 Harinas   (RD$50)
// 3 Quesos    (RD$100)
//
// El sistema debe calcular:
//
// (2 x 50) + (3 x 100)
//
// Resultado esperado:
//
// RD$400
//
// Si el cálculo cambia por un error futuro,
// esta prueba protegerá la regla de negocio.
// =============================================================