<?php

declare(strict_types=1);

namespace App\Modules\Producto\DTOs;

use App\Modules\Producto\Http\Requests\StoreProductoRequest;

final readonly class CreateProductoDTO
{
    public function __construct(
        public string $nombre,
        public ?string $codigo,
        public ?string $descripcion,
        public ?int $categoriaId,
        public ?int $marcaId,
        public ?int $unidadMedidaId,
        public ?int $impuestoId,
        public ?string $tipoProducto,
        public ?string $tipoContable,
        public float $precioVenta,
        public float $precioCompra,
        public float $costo,
        public bool $manejaInventario,
        public float $stockActual,
        public float $stockMinimo,
        public ?int $cuentaIngresoId,
        public ?int $cuentaInventarioId,
        public ?int $cuentaCostoId,
        public ?int $cuentaGastoId,
        public bool $activo,
        public ?string $presentacionCompraPorDefecto,
        public ?float $factorCompraPorDefecto
    ) {}

    public static function fromRequest(StoreProductoRequest $request): self
    {
        return new self(
            nombre: $request->validated('nombre'),
            codigo: $request->validated('codigo'),
            descripcion: $request->validated('descripcion'),
            categoriaId: $request->validated('categoria_id') ? (int) $request->validated('categoria_id') : null,
            marcaId: $request->validated('marca_id') ? (int) $request->validated('marca_id') : null,
            unidadMedidaId: $request->validated('unidad_medida_id') ? (int) $request->validated('unidad_medida_id') : null,
            impuestoId: $request->validated('impuesto_id') ? (int) $request->validated('impuesto_id') : null,
            tipoProducto: $request->validated('tipo_producto'),
            tipoContable: $request->validated('tipo_contable'),
            precioVenta: (float) $request->validated('precio_venta', 0.0),
            precioCompra: (float) $request->validated('precio_compra', 0.0),
            costo: (float) $request->validated('costo', 0.0),
            manejaInventario: (bool) $request->validated('maneja_inventario', false),
            stockActual: (float) $request->validated('stock_actual', 0.0),
            stockMinimo: (float) $request->validated('stock_minimo', 0.0),
            cuentaIngresoId: $request->validated('cuenta_ingreso_id') ? (int) $request->validated('cuenta_ingreso_id') : null,
            cuentaInventarioId: $request->validated('cuenta_inventario_id') ? (int) $request->validated('cuenta_inventario_id') : null,
            cuentaCostoId: $request->validated('cuenta_costo_id') ? (int) $request->validated('cuenta_costo_id') : null,
            cuentaGastoId: $request->validated('cuenta_gasto_id') ? (int) $request->validated('cuenta_gasto_id') : null,
            activo: (bool) $request->validated('activo', true),
            presentacionCompraPorDefecto: $request->validated('presentacion_compra_por_defecto'),
            factorCompraPorDefecto: $request->validated('factor_compra_por_defecto') ? (float) $request->validated('factor_compra_por_defecto') : null
        );
    }

    public function toArray(): array
    {
        return [
            'nombre' => $this->nombre,
            'codigo' => $this->codigo,
            'descripcion' => $this->descripcion,
            'categoria_id' => $this->categoriaId,
            'marca_id' => $this->marcaId,
            'unidad_medida_id' => $this->unidadMedidaId,
            'impuesto_id' => $this->impuestoId,
            'tipo_producto' => $this->tipoProducto,
            'tipo_contable' => $this->tipoContable,
            'precio_venta' => $this->precioVenta,
            'precio_compra' => $this->precioCompra,
            'costo' => $this->costo,
            'maneja_inventario' => $this->manejaInventario,
            'stock_actual' => $this->stockActual,
            'stock_minimo' => $this->stockMinimo,
            'cuenta_ingreso_id' => $this->cuentaIngresoId,
            'cuenta_inventario_id' => $this->cuentaInventarioId,
            'cuenta_costo_id' => $this->cuentaCostoId,
            'cuenta_gasto_id' => $this->cuentaGastoId,
            'activo' => $this->activo,
            'presentacion_compra_por_defecto' => $this->presentacionCompraPorDefecto,
            'factor_compra_por_defecto' => $this->factorCompraPorDefecto,
        ];
    }
}
