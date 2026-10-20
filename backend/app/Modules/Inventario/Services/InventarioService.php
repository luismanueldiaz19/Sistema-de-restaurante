<?php

declare(strict_types=1);

namespace App\Modules\Inventario\Services;

use App\Models\MovimientoInventario;
use App\Models\Producto;
use App\Modules\Contabilidad\DTOs\RegistrarAsientoDTO;
use App\Modules\Contabilidad\Services\ContabilidadService;
use App\Modules\Inventario\DTOs\FiltroKardexDTO;
use App\Modules\Inventario\DTOs\RegistrarAjusteDTO;
use App\Modules\Inventario\Enums\TipoMovimientoEnum;
use App\Modules\Inventario\Exceptions\InventarioException;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;
use Illuminate\Database\Eloquent\Collection;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

class InventarioService
{
    public function __construct(
        private readonly RecetaService $recetaService,
        private readonly ?ContabilidadService $contabilidadService = null
    ) {}

    private function getContabilidadService(): ?ContabilidadService
    {
        return $this->contabilidadService ?? (app()->bound(ContabilidadService::class) ? app(ContabilidadService::class) : null);
    }

    /**
     * Registrar un ajuste manual de inventario (Entrada o Salida)
     * Permite saldo negativo en stock si la disponibilidad física lo requiere.
     * Solo opera sobre productos que manejan inventario y no sean servicios.
     */
    public function registrarAjuste(RegistrarAjusteDTO $dto): MovimientoInventario
    {
        return DB::transaction(function () use ($dto) {
            $producto = Producto::lockForUpdate()->findOrFail($dto->productoId);

            if (!$producto->maneja_inventario || $producto->tipo_producto === 'SERVICIO') {
                throw new InventarioException("El producto '{$producto->nombre}' no maneja inventario o es un servicio.");
            }

            // Permite saldo negativo en stock físico
            if ($dto->tipo === TipoMovimientoEnum::SALIDA) {
                $producto->stock_actual -= $dto->cantidad;
            } else {
                $producto->stock_actual += $dto->cantidad;
            }

            $producto->save();

            $movimiento = MovimientoInventario::create([
                'producto_id' => $producto->id,
                'tipo'        => $dto->tipo->value,
                'cantidad'    => $dto->cantidad,
                'referencia'  => $dto->motivo,
                'fecha'       => now(),
            ]);

            // Intentar registrar el asiento contable por partida doble si el producto tiene costo
            $this->intentarAsientoAjuste($producto, $dto);

            return $movimiento->load(['producto.categoria', 'producto.unidadMedida']);
        });
    }

    /**
     * Generar asiento contable automático para el ajuste de inventario (Mermas o Sobrantes)
     */
    private function intentarAsientoAjuste(Producto $producto, RegistrarAjusteDTO $dto): void
    {
        try {
            $costoUnitario = (float) $producto->costo;
            $valorTotal = round($dto->cantidad * $costoUnitario, 2);

            if ($valorTotal <= 0) {
                return;
            }

            $contabilidad = $this->getContabilidadService();
            if (!$contabilidad) {
                return;
            }

            $glosa = "Ajuste de inventario ({$dto->tipo->value}): {$producto->nombre} ({$dto->cantidad} un.) - {$dto->motivo}";
            $referencia = "AJUSTE-PROD-{$producto->id}-" . now()->format('YmdHis');

            $asientoDto = new RegistrarAsientoDTO(
                tipo_transaccion: 'ajuste_inventario',
                subtotal: $valorTotal,
                itbis: 0.0,
                total: $valorTotal,
                referencia: $referencia,
                glosa: $glosa,
                usuario_id: auth()->id() ?? 1,
                custom_configs: [
                    'tipo_ajuste' => $dto->tipo->value,
                ],
                costo: 0.0,
                fecha: now()->toDateString()
            );

            $contabilidad->registrarAsientoAuto($asientoDto);
        } catch (\Throwable $e) {
            // Se registra en logs pero no detiene la operación de inventario si falta configurar cuentas
            Log::warning("No se pudo generar asiento contable para ajuste de inventario: " . $e->getMessage());
        }
    }

    /**
     * Obtener el historial de movimientos de inventario (Kardex) con filtros y paginación
     */
    public function getMovimientos(FiltroKardexDTO $dto): LengthAwarePaginator
    {
        $query = MovimientoInventario::with(['producto.categoria', 'producto.unidadMedida'])
            ->orderBy('fecha', 'desc')
            ->orderBy('id', 'desc');

        if ($dto->productoId) {
            $query->where('producto_id', $dto->productoId);
        }

        if ($dto->tipo) {
            $query->where('tipo', strtoupper($dto->tipo));
        }

        if ($dto->fechaDesde) {
            $query->where('fecha', '>=', $dto->fechaDesde . ' 00:00:00');
        }

        if ($dto->fechaHasta) {
            $query->where('fecha', '<=', $dto->fechaHasta . ' 23:59:59');
        }

        if ($dto->search) {
            $term = $dto->search;
            $query->where(function ($q) use ($term) {
                $q->where('referencia', 'like', "%{$term}%")
                  ->orWhereHas('producto', function ($qp) use ($term) {
                      $qp->where('nombre', 'like', "%{$term}%")
                         ->orWhere('codigo', 'like', "%{$term}%");
                  });
            });
        }

        return $query->paginate($dto->perPage);
    }

    /**
     * Obtener listado de existencias actuales con valorización monetaria
     */
    public function getExistencias(array $filters = []): array
    {
        $query = Producto::with(['categoria', 'unidadMedida', 'marca'])
            ->where('maneja_inventario', true)
            ->where('tipo_producto', '!=', 'SERVICIO')
            ->where('activo', true);

        if (!empty($filters['categoria_id'])) {
            $query->where('categoria_id', $filters['categoria_id']);
        }

        if (!empty($filters['search'])) {
            $term = $filters['search'];
            $query->where(function ($q) use ($term) {
                $q->where('nombre', 'like', "%{$term}%")
                  ->orWhere('codigo', 'like', "%{$term}%");
            });
        }

        $productos = $query->orderBy('nombre', 'asc')->get();

        $totalUnidades = 0.0;
        $valorTotalCosto = 0.0;
        $valorTotalVenta = 0.0;
        $bajoMinimoCount = 0;

        $items = $productos->map(function ($p) use (&$totalUnidades, &$valorTotalCosto, &$valorTotalVenta, &$bajoMinimoCount) {
            $stock = (float) $p->stock_actual;
            $minimo = (float) $p->stock_minimo;
            $costo = (float) $p->costo;
            $precioVenta = (float) $p->precio_venta;

            $valorCosto = round($stock * $costo, 2);
            $valorVenta = round($stock * $precioVenta, 2);

            $totalUnidades += $stock;
            $valorTotalCosto += $valorCosto;
            $valorTotalVenta += $valorVenta;

            $esBajoMinimo = $stock <= $minimo;
            if ($esBajoMinimo) {
                $bajoMinimoCount++;
            }

            return [
                'id'            => $p->id,
                'codigo'        => $p->codigo,
                'nombre'        => $p->nombre,
                'tipo_producto' => $p->tipo_producto,
                'categoria'     => $p->categoria?->nombre,
                'unidad_medida' => $p->unidadMedida?->nombre,
                'stock_actual'  => $stock,
                'stock_minimo'  => $minimo,
                'costo'         => $costo,
                'precio_venta'  => $precioVenta,
                'valor_costo'   => $valorCosto,
                'valor_venta'   => $valorVenta,
                'bajo_minimo'   => $esBajoMinimo,
            ];
        });

        return [
            'resumen' => [
                'total_productos'     => $productos->count(),
                'total_unidades'      => round($totalUnidades, 2),
                'valor_total_costo'   => round($valorTotalCosto, 2),
                'valor_total_venta'   => round($valorTotalVenta, 2),
                'productos_en_alerta' => $bajoMinimoCount,
            ],
            'productos' => $items,
        ];
    }

    /**
     * Obtener listado de productos con stock en o por debajo del mínimo (Alertas de reposición)
     */
    public function getProductosBajoStockMinimo(): Collection
    {
        return Producto::with(['categoria', 'unidadMedida'])
            ->where('maneja_inventario', true)
            ->where('tipo_producto', '!=', 'SERVICIO')
            ->where('activo', true)
            ->whereColumn('stock_actual', '<=', 'stock_minimo')
            ->orderBy('stock_actual', 'asc')
            ->get();
    }

    /**
     * Procesar descuento de inventario al realizar una venta (descuento directo o explosión de recetas)
     * Permite que el stock llegue a números negativos si la disponibilidad física lo requiere.
     * Solo descuenta ítems que manejan inventario y no son servicios.
     */
    public function procesarSalidaVenta(int $productoId, float $cantidadVenta, string $referencia = ''): void
    {
        $producto = Producto::with('recetas.ingrediente')->findOrFail($productoId);

        // Si es un servicio, nunca mueve inventario
        if ($producto->tipo_producto === 'SERVICIO') {
            return;
        }

        // Si es PLATO o COMBO con receta configurada, se descuentan las materias primas
        if (in_array($producto->tipo_producto, ['PLATO', 'COMBO'], true) && $producto->recetas->isNotEmpty()) {
            foreach ($producto->recetas as $receta) {
                $ingrediente = $receta->ingrediente;
                // Verificar que el ingrediente maneje inventario y no sea servicio
                if ($ingrediente && $ingrediente->maneja_inventario && $ingrediente->tipo_producto !== 'SERVICIO') {
                    $cantidadADescontar = (float) $receta->cantidad * $cantidadVenta;
                    $this->descontarStockDirecto(
                        productoId: (int) $receta->ingrediente_producto_id,
                        cantidad: $cantidadADescontar,
                        referencia: "VENTA: {$referencia}"
                    );
                }
            }
        } elseif ($producto->maneja_inventario) {
            // Venta directa de producto inventariable (permite negativo)
            $this->descontarStockDirecto(
                productoId: $productoId,
                cantidad: $cantidadVenta,
                referencia: "VENTA: {$referencia}"
            );
        }
    }

    /**
     * Procesar entrada de inventario al recibir una compra de proveedor
     */
    public function procesarEntradaCompra(int $productoId, float $cantidad, string $referencia = ''): void
    {
        $producto = Producto::find($productoId);

        if (!$producto || !$producto->maneja_inventario || $producto->tipo_producto === 'SERVICIO') {
            return;
        }

        $producto->increment('stock_actual', $cantidad);

        MovimientoInventario::create([
            'producto_id' => $productoId,
            'tipo'        => TipoMovimientoEnum::ENTRADA->value,
            'cantidad'    => $cantidad,
            'referencia'  => "COMPRA: {$referencia}",
            'fecha'       => now(),
        ]);
    }

    /**
     * Descontar stock directo de un producto y registrar movimiento de SALIDA.
     * Permite saldo negativo.
     */
    private function descontarStockDirecto(int $productoId, float $cantidad, string $referencia): void
    {
        $producto = Producto::find($productoId);
        if (!$producto || !$producto->maneja_inventario || $producto->tipo_producto === 'SERVICIO') {
            return;
        }

        $producto->decrement('stock_actual', $cantidad);

        MovimientoInventario::create([
            'producto_id' => $productoId,
            'tipo'        => TipoMovimientoEnum::SALIDA->value,
            'cantidad'    => $cantidad,
            'referencia'  => $referencia,
            'fecha'       => now(),
        ]);
    }
}
