<?php

declare(strict_types=1);

namespace Tests\Feature\Inventory;

use App\Models\MovimientoInventario;
use App\Models\Producto;
use App\Models\User;
use App\Modules\Inventario\DTOs\RegistrarAjusteDTO;
use App\Modules\Inventario\DTOs\GuardarRecetaDTO;
use App\Modules\Inventario\Enums\TipoMovimientoEnum;
use App\Modules\Inventario\Exceptions\InventarioException;
use App\Modules\Inventario\Services\InventarioService;
use App\Modules\Inventario\Services\RecetaService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Spatie\Permission\Models\Permission;
use Tests\TestCase;

class InventarioModuloTest extends TestCase
{
    use RefreshDatabase;

    private User $user;

    protected function setUp(): void
    {
        parent::setUp();

        $this->user = User::factory()->create();

        // Crear permisos requeridos para las rutas
        Permission::findOrCreate('ver_inventario', 'web');
        Permission::findOrCreate('gestionar_recetas', 'web');

        $this->user->givePermissionTo(['ver_inventario', 'gestionar_recetas']);
    }

    public function test_ajuste_entrada_incrementa_stock_y_crea_movimiento(): void
    {
        $producto = Producto::factory()->create([
            'nombre'            => 'Arroz Blanco',
            'maneja_inventario' => true,
            'stock_actual'      => 10,
        ]);

        Sanctum::actingAs($this->user);

        $response = $this->postJson('/api/inventario/ajuste', [
            'producto_id' => $producto->id,
            'tipo'        => 'ENTRADA',
            'cantidad'    => 15,
            'motivo'      => 'Compra de emergencia',
        ]);

        $response->assertStatus(201)
            ->assertJson([
                'success' => true,
                'message' => 'Ajuste de inventario guardado correctamente',
            ]);

        $producto->refresh();
        $this->assertEquals(25, $producto->stock_actual);

        $this->assertDatabaseHas('movimientos_inventario', [
            'producto_id' => $producto->id,
            'tipo'        => 'ENTRADA',
            'cantidad'    => 15,
            'referencia'  => 'Compra de emergencia',
        ]);
    }

    public function test_ajuste_salida_permite_saldo_negativo_por_disponibilidad(): void
    {
        // En restaurantes es normal que el stock físico quede negativo temporalmente
        // si se despacha comida antes de asentar las compras en el sistema
        $producto = Producto::factory()->create([
            'nombre'            => 'Carne de Res Molida',
            'maneja_inventario' => true,
            'stock_actual'      => 3,
        ]);

        Sanctum::actingAs($this->user);

        $response = $this->postJson('/api/inventario/ajuste', [
            'producto_id' => $producto->id,
            'tipo'        => 'SALIDA',
            'cantidad'    => 10,
            'motivo'      => 'Despacho a cocina sin compra asentada',
        ]);

        $response->assertStatus(201)
            ->assertJson([
                'success' => true,
            ]);

        $producto->refresh();
        $this->assertEquals(-7, $producto->stock_actual);

        $this->assertDatabaseHas('movimientos_inventario', [
            'producto_id' => $producto->id,
            'tipo'        => 'SALIDA',
            'cantidad'    => 10,
            'referencia'  => 'Despacho a cocina sin compra asentada',
        ]);
    }

    public function test_ajuste_rechaza_productos_que_no_manejan_inventario_o_son_servicios(): void
    {
        $servicio = Producto::factory()->create([
            'nombre'            => 'Servicio de Entrega a Domicilio',
            'tipo_producto'     => 'SERVICIO',
            'maneja_inventario' => false,
        ]);

        Sanctum::actingAs($this->user);

        $response = $this->postJson('/api/inventario/ajuste', [
            'producto_id' => $servicio->id,
            'tipo'        => 'SALIDA',
            'cantidad'    => 1,
            'motivo'      => 'Intento de merma en servicio',
        ]);

        $response->assertStatus(400)
            ->assertJson([
                'success' => false,
            ]);
    }

    public function test_consultar_movimientos_retorna_lista_compatible_con_frontend(): void
    {
        $producto = Producto::factory()->create(['maneja_inventario' => true]);

        MovimientoInventario::create([
            'producto_id' => $producto->id,
            'tipo'        => 'ENTRADA',
            'cantidad'    => 50,
            'referencia'  => 'Carga inicial',
            'fecha'       => now(),
        ]);

        Sanctum::actingAs($this->user);

        $response = $this->getJson('/api/inventario/movimientos');

        $response->assertStatus(200)
            ->assertJsonStructure([
                'success',
                'message',
                'data',
                'meta' => ['current_page', 'last_page', 'per_page', 'total'],
            ]);

        $data = $response->json('data');
        $this->assertIsArray($data);
        $this->assertCount(1, $data);
        $this->assertEquals('Carga inicial', $data[0]['referencia']);
    }

    public function test_consultar_existencias_y_alertas_stock(): void
    {
        Producto::factory()->create([
            'nombre'            => 'Producto En Alerta',
            'maneja_inventario' => true,
            'stock_actual'      => 2,
            'stock_minimo'      => 5,
            'costo'             => 100,
            'precio_venta'      => 150,
            'activo'            => true,
        ]);

        Producto::factory()->create([
            'nombre'            => 'Producto Con Stock Suficiente',
            'maneja_inventario' => true,
            'stock_actual'      => 50,
            'stock_minimo'      => 10,
            'costo'             => 20,
            'precio_venta'      => 40,
            'activo'            => true,
        ]);

        Sanctum::actingAs($this->user);

        // 1. Probar existencias valorizadas
        $responseExistencias = $this->getJson('/api/inventario/existencias');
        $responseExistencias->assertStatus(200)
            ->assertJson([
                'success' => true,
            ]);

        $resumen = $responseExistencias->json('data.resumen');
        $this->assertEquals(2, $resumen['total_productos']);
        $this->assertEquals(1, $resumen['productos_en_alerta']);

        // 2. Probar alertas de stock mínimo
        $responseAlertas = $this->getJson('/api/inventario/alertas-stock');
        $responseAlertas->assertStatus(200);

        $alertas = $responseAlertas->json('data');
        $this->assertCount(1, $alertas);
        $this->assertEquals('Producto En Alerta', $alertas[0]['nombre']);
    }

    public function test_guardar_receta_actualiza_costo_del_plato_automaticamente(): void
    {
        $plato = Producto::factory()->create([
            'nombre'        => 'Mofongo con Camarones',
            'tipo_producto' => 'PLATO',
            'costo'         => 0,
        ]);

        $platano = Producto::factory()->materiaPrima()->create([
            'nombre' => 'Plátano Verde',
            'costo'  => 30,
        ]);

        $camarones = Producto::factory()->materiaPrima()->create([
            'nombre' => 'Camarones',
            'costo'  => 120,
        ]);

        Sanctum::actingAs($this->user);

        $response = $this->putJson("/api/recetas/{$plato->id}", [
            'ingredientes' => [
                [
                    'ingrediente_producto_id' => $platano->id,
                    'cantidad'                => 3, // 3 * 30 = 90
                ],
                [
                    'ingrediente_producto_id' => $camarones->id,
                    'cantidad'                => 2, // 2 * 120 = 240
                ],
            ],
        ]);

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
                'message' => 'Receta actualizada correctamente.',
            ]);

        // Costo esperado del plato: 90 + 240 = 330
        $plato->refresh();
        $this->assertEquals(330, (float) $plato->costo);

        $this->assertDatabaseHas('recetas', [
            'producto_id'             => $plato->id,
            'ingrediente_producto_id' => $platano->id,
            'cantidad'                => 3,
        ]);

        $this->assertDatabaseHas('recetas', [
            'producto_id'             => $plato->id,
            'ingrediente_producto_id' => $camarones->id,
            'cantidad'                => 2,
        ]);
    }

    public function test_procesar_salida_venta_permite_stock_negativo_e_ignora_servicios(): void
    {
        $producto = Producto::factory()->create([
            'nombre'            => 'Cerveza Presidente',
            'tipo_producto'     => 'PRODUCTO',
            'maneja_inventario' => true,
            'stock_actual'      => 2,
        ]);

        $servicio = Producto::factory()->create([
            'nombre'            => 'Propina Legal 10%',
            'tipo_producto'     => 'SERVICIO',
            'maneja_inventario' => false,
            'stock_actual'      => 0,
        ]);

        $inventarioService = app(InventarioService::class);

        // Vender 5 cervezas cuando solo hay 2 en sistema -> stock queda en -3
        $inventarioService->procesarSalidaVenta($producto->id, 5, 'Factura-Prueba-001');

        $producto->refresh();
        $this->assertEquals(-3, $producto->stock_actual);

        // El servicio no debe moverse
        $inventarioService->procesarSalidaVenta($servicio->id, 1, 'Factura-Prueba-002');
        $servicio->refresh();
        $this->assertEquals(0, $servicio->stock_actual);
        $this->assertDatabaseMissing('movimientos_inventario', [
            'producto_id' => $servicio->id,
        ]);
    }
}
