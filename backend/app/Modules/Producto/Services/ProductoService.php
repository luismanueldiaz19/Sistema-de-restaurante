<?php

declare(strict_types=1);

namespace App\Modules\Producto\Services;

use App\Models\Categoria;
use App\Models\Impuesto;
use App\Models\Marca;
use App\Models\Producto;
use App\Models\UnidadMedida;
use App\Modules\Inventario\DTOs\RegistrarAjusteDTO;
use App\Modules\Inventario\Enums\TipoMovimientoEnum;
use App\Modules\Inventario\Services\InventarioService;
use App\Modules\Producto\DTOs\CreateProductoDTO;
use App\Modules\Producto\DTOs\UpdateProductoDTO;
use App\Modules\Producto\Enums\TipoContableEnum;
use App\Modules\Producto\Enums\TipoProductoEnum;
use App\Modules\Producto\Exceptions\ProductoException;
use App\Modules\Producto\Repositories\Contracts\ProductoRepositoryInterface;
use Exception;
use Illuminate\Pagination\LengthAwarePaginator;
use Illuminate\Support\Facades\DB;
use Rap2hpoutre\FastExcel\FastExcel;

class ProductoService
{
    public function __construct(
        private readonly ProductoRepositoryInterface $productoRepository,
        private readonly ?InventarioService $inventarioService = null
    ) {}

    private function getInventarioService(): ?InventarioService
    {
        return $this->inventarioService ?? (app()->bound(InventarioService::class) ? app(InventarioService::class) : null);
    }

    public function getAll(int $perPage = 15, array $filters = []): LengthAwarePaginator
    {
        return $this->productoRepository->getAll($perPage, $filters);
    }

    public function getById(int $id): Producto
    {
        return $this->productoRepository->findById($id);
    }

    /**
     * Normaliza el nombre del producto siempre a UPPERCASE limpio.
     */
    public function normalizarNombre(string $nombre): string
    {
        $limpio = preg_replace('/\s+/', ' ', trim($nombre));
        return mb_strtoupper((string) $limpio, 'UTF-8');
    }

    /**
     * Genera un código SKU único basado en el nombre del producto.
     */
    public function generarCodigoUnico(string $nombre, array &$codigosReservados = []): string
    {
        $nombreUpper = $this->normalizarNombre($nombre);
        $sinAcentos = strtr($nombreUpper, [
            'Á' => 'A', 'É' => 'E', 'Í' => 'I', 'Ó' => 'O', 'Ú' => 'U', 'Ü' => 'U', 'Ñ' => 'N',
        ]);

        $palabras = array_values(array_filter(
             explode(' ', preg_replace('/[^A-Z0-9\s]/', '', $sinAcentos) ?? ''),
            fn ($w) => strlen($w) > 0
        ));

        $prefix = 'PRD';
        if (count($palabras) === 1) {
            $prefix = substr($palabras[0], 0, 3);
        } elseif (count($palabras) === 2) {
            $prefix = substr($palabras[0], 0, 2) . substr($palabras[1], 0, 1);
        } elseif (count($palabras) >= 3) {
            $prefix = $palabras[0][0] . $palabras[1][0] . $palabras[2][0];
        }

        $prefix = str_pad(preg_replace('/[^A-Z0-9]/', '', $prefix) ?: 'PRD', 3, 'X');

        $secuencia = Producto::count() + count($codigosReservados) + 1;
        $intentos = 0;

        do {
            $numero = str_pad((string) $secuencia, 4, '0', STR_PAD_LEFT);
            $candidato = "{$prefix}-{$numero}";
            $existeEnBd = Producto::where('codigo', $candidato)->exists();
            $existeEnMemoria = in_array($candidato, $codigosReservados, true);

            if (!$existeEnBd && !$existeEnMemoria) {
                $codigosReservados[] = $candidato;
                return $candidato;
            }

            $secuencia++;
            $intentos++;
        } while ($intentos < 5000);

        $fallback = $prefix . '-' . strtoupper(substr(uniqid(), -5));
        $codigosReservados[] = $fallback;
        return $fallback;
    }

    public function create(CreateProductoDTO $dto): Producto
    {
        return DB::transaction(function () use ($dto) {
            try {
                $data = $dto->toArray();
                $data['nombre'] = $this->normalizarNombre((string) $data['nombre']);

                if (empty($data['codigo'])) {
                    $reservados = [];
                    $data['codigo'] = $this->generarCodigoUnico($data['nombre'], $reservados);
                } else {
                    $data['codigo'] = mb_strtoupper(trim((string) $data['codigo']), 'UTF-8');
                }

                $stockInicial = (float) ($data['stock_actual'] ?? 0);
                $manejaInv = (bool) ($data['maneja_inventario'] ?? true);

                // Si tiene stock inicial y maneja inventario, iniciamos en 0 y registramos entrada por Kardex/Contabilidad
                if ($manejaInv && $stockInicial > 0 && $data['tipo_producto'] !== 'SERVICIO') {
                    $data['stock_actual'] = 0;
                }

                $producto = $this->productoRepository->create($data);

                if ($manejaInv && $stockInicial > 0 && $producto->tipo_producto !== 'SERVICIO') {
                    $invService = $this->getInventarioService();
                    if ($invService) {
                        $invService->registrarAjuste(new RegistrarAjusteDTO(
                            productoId: (int) $producto->id,
                            tipo: TipoMovimientoEnum::ENTRADA,
                            cantidad: $stockInicial,
                            motivo: 'INVENTARIO INICIAL AL CREAR PRODUCTO'
                        ));
                        $producto->refresh();
                    } else {
                        $producto->update(['stock_actual' => $stockInicial]);
                    }
                }

                return $producto->load(['categoria', 'marca', 'unidadMedida', 'impuesto']);
            } catch (Exception $e) {
                throw new ProductoException("Error al crear el producto: " . $e->getMessage());
            }
        });
    }

    public function update(int $id, UpdateProductoDTO $dto): Producto
    {
        return DB::transaction(function () use ($id, $dto) {
            try {
                $data = $dto->toArray();
                if (isset($data['nombre'])) {
                    $data['nombre'] = $this->normalizarNombre((string) $data['nombre']);
                }
                if (array_key_exists('codigo', $data)) {
                    if (empty($data['codigo'])) {
                        $productoActual = $this->productoRepository->findById($id);
                        $reservados = [];
                        $data['codigo'] = $productoActual->codigo ?: $this->generarCodigoUnico(
                            $data['nombre'] ?? $productoActual->nombre,
                            $reservados
                        );
                    } else {
                        $data['codigo'] = mb_strtoupper(trim((string) $data['codigo']), 'UTF-8');
                    }
                }

                return $this->productoRepository->update($id, $data);
            } catch (Exception $e) {
                throw new ProductoException("Error al actualizar el producto: " . $e->getMessage());
            }
        });
    }

    public function delete(int $id): bool
    {
        return DB::transaction(function () use ($id) {
            try {
                return $this->productoRepository->delete($id);
            } catch (Exception $e) {
                throw new ProductoException("Error al eliminar el producto: " . $e->getMessage());
            }
        });
    }

    /**
     * Genera las filas de ejemplo para la plantilla descargable de productos inventariables.
     */
    public function obtenerFilasPlantillaBase(): array
    {
        return [
            [
                'nombre'            => 'COCA COLA 20 OZ',
                'codigo'            => '', // Vacío para demostrar autogeneración
                'descripcion'       => 'REFRESCO DE COLA BOTELLA PLASTICA 20 OZ',
                'categoria'         => 'Bebidas',
                'marca'             => 'Coca Cola',
                'unidad_medida'     => 'BOT',
                'tipo_producto'     => 'PRODUCTO',
                'tipo_contable'     => 'INVENTARIO',
                'precio_venta'      => 75.00,
                'costo'             => 45.00,
                'impuesto_id'       => 1,
                'stock_actual'      => 24,
                'stock_minimo'      => 6,
                'maneja_inventario' => 'SI',
            ],
            [
                'nombre'            => 'AGUA DASANI 500 ML',
                'codigo'            => 'AGU-0001',
                'descripcion'       => 'AGUA PURIFICADA BOTELLA 500 ML',
                'categoria'         => 'Bebidas',
                'marca'             => 'Coca Cola',
                'unidad_medida'     => 'BOT',
                'tipo_producto'     => 'PRODUCTO',
                'tipo_contable'     => 'INVENTARIO',
                'precio_venta'      => 40.00,
                'costo'             => 20.00,
                'impuesto_id'       => 2,
                'stock_actual'      => 48,
                'stock_minimo'      => 12,
                'maneja_inventario' => 'SI',
            ],
            [
                'nombre'            => 'QUESO CHEDDAR LAMINADO LB',
                'codigo'            => '',
                'descripcion'       => 'INSUMO PARA HAMBURGUESAS Y SANDWICHES',
                'categoria'         => 'Comida',
                'marca'             => 'Generica',
                'unidad_medida'     => 'LB',
                'tipo_producto'     => 'MATERIA_PRIMA',
                'tipo_contable'     => 'INVENTARIO',
                'precio_venta'      => 0.00,
                'costo'             => 210.00,
                'impuesto_id'       => 1,
                'stock_actual'      => 15,
                'stock_minimo'      => 5,
                'maneja_inventario' => 'SI',
            ],
        ];
    }

    /**
     * Analiza y valida un archivo Excel/CSV sin guardar aún en la base de datos.
     * Devuelve cada fila con su estado: LISTO, DUPLICADO_BD, DUPLICADO_ARCHIVO, ERROR.
     */
    public function previsualizarImportacion(string $filePath): array
    {
        try {
            $rawRows = (new FastExcel)->import($filePath);
        } catch (Exception $e) {
            throw new ProductoException('Error leyendo el archivo Excel/CSV: ' . $e->getMessage());
        }

        if ($rawRows->isEmpty()) {
            throw new ProductoException('El archivo está vacío o no contiene filas válidas.');
        }

        // Pre-cargar catálogos y productos actuales para validación rápida en memoria
        $productosExistentes = Producto::select('id', 'nombre', 'codigo')->get();
        $nombresEnBd = [];
        $codigosEnBd = [];
        foreach ($productosExistentes as $p) {
            $nombresEnBd[$this->normalizarNombre((string) $p->nombre)] = $p->id;
            if (!empty($p->codigo)) {
                $codigosEnBd[mb_strtoupper(trim((string) $p->codigo), 'UTF-8')] = $p->id;
            }
        }

        $categorias = Categoria::all();
        $marcas = Marca::all();
        $unidades = UnidadMedida::all();
        $impuestos = Impuesto::all();

        $defaultCategoriaId = $categorias->first()?->id;
        $defaultMarcaId = $marcas->first()?->id;
        $defaultUnidadId = $unidades->firstWhere('abreviatura', 'UND')?->id ?? $unidades->first()?->id;
        $defaultImpuestoId = $impuestos->first()?->id;

        $tiposProductoValidos = array_column(TipoProductoEnum::cases(), 'value');
        $tiposContablesValidos = array_column(TipoContableEnum::cases(), 'value');

        $nombresEnArchivo = [];
        $codigosEnArchivo = [];
        $codigosReservados = array_keys($codigosEnBd);

        $filasProcesadas = [];
        $conteoListos = 0;
        $conteoDuplicados = 0;
        $conteoErrores = 0;

        foreach ($rawRows as $index => $row) {
            $numeroFila = $index + 2; // Fila 1 es cabecera
            $normalizedRow = [];
            foreach ($row as $key => $value) {
                $cleanKey = trim(mb_strtolower((string) $key, 'UTF-8'));
                $normalizedRow[$cleanKey] = $value;
            }

            // Ignorar filas completamente vacías
            $valoresNoVacios = array_filter($normalizedRow, fn ($v) => $v !== null && trim((string) $v) !== '');
            if (empty($valoresNoVacios)) {
                continue;
            }

            $erroresFila = [];
            $advertenciasFila = [];
            $estado = 'LISTO';

            // 1. Nombre (SIEMPRE UPPERCASE)
            $rawNombre = (string) ($normalizedRow['nombre'] ?? $normalizedRow['producto'] ?? '');
            $nombre = $this->normalizarNombre($rawNombre);

            if ($nombre === '') {
                $erroresFila[] = 'El nombre del producto es obligatorio.';
            }

            // 2. Código (Autogenerado si viene vacío)
            $rawCodigo = trim((string) ($normalizedRow['codigo'] ?? $normalizedRow['sku'] ?? ''));
            $codigoAutogenerado = false;
            if ($rawCodigo === '') {
                $codigo = $this->generarCodigoUnico($nombre ?: 'PRD', $codigosReservados);
                $codigoAutogenerado = true;
            } else {
                $codigo = mb_strtoupper($rawCodigo, 'UTF-8');
            }

            // 3. Descripción
            $rawDesc = trim((string) ($normalizedRow['descripcion'] ?? $normalizedRow['detalle'] ?? $normalizedRow['destalle'] ?? ''));
            $descripcion = $rawDesc !== '' ? mb_strtoupper($rawDesc, 'UTF-8') : null;

            // 4. Tipo de Producto y Tipo Contable
            $rawTipoProd = mb_strtoupper(trim((string) ($normalizedRow['tipo_producto'] ?? $normalizedRow['tipo'] ?? 'PRODUCTO')), 'UTF-8');
            if ($rawTipoProd === '') {
                $rawTipoProd = 'PRODUCTO';
            }
            if (!in_array($rawTipoProd, $tiposProductoValidos, true)) {
                $erroresFila[] = "Tipo de producto inválido ({$rawTipoProd}). Permitidos: " . implode(', ', $tiposProductoValidos);
            }

            $rawTipoContable = mb_strtoupper(trim((string) ($normalizedRow['tipo_contable'] ?? $normalizedRow['contable'] ?? 'INVENTARIO')), 'UTF-8');
            if ($rawTipoContable === '') {
                $rawTipoContable = 'INVENTARIO';
            }
            if (!in_array($rawTipoContable, $tiposContablesValidos, true)) {
                $erroresFila[] = "Tipo contable inválido ({$rawTipoContable}). Permitidos: " . implode(', ', $tiposContablesValidos);
            }

            // 5. Verificación de Cantidades y Precios
            $rawPrecioVenta = $normalizedRow['precio_venta'] ?? $normalizedRow['precio'] ?? 0;
            $rawCosto = $normalizedRow['costo'] ?? $normalizedRow['ultimo_costo'] ?? $normalizedRow['precio_compra'] ?? 0;
            $rawStockActual = $normalizedRow['stock_actual'] ?? $normalizedRow['stock'] ?? $normalizedRow['cantidad'] ?? 0;
            $rawStockMinimo = $normalizedRow['stock_minimo'] ?? $normalizedRow['minimo'] ?? 0;

            if ($rawPrecioVenta === '' || $rawPrecioVenta === null) {
                $rawPrecioVenta = 0;
            }
            if ($rawCosto === '' || $rawCosto === null) {
                $rawCosto = 0;
            }
            if ($rawStockActual === '' || $rawStockActual === null) {
                $rawStockActual = 0;
            }
            if ($rawStockMinimo === '' || $rawStockMinimo === null) {
                $rawStockMinimo = 0;
            }

            if (!is_numeric($rawPrecioVenta) || (float) $rawPrecioVenta < 0) {
                $erroresFila[] = "Precio de venta inválido ({$rawPrecioVenta}). Debe ser un número >= 0.";
            }
            if (!is_numeric($rawCosto) || (float) $rawCosto < 0) {
                $erroresFila[] = "Costo inválido ({$rawCosto}). Debe ser un número >= 0.";
            }
            if (!is_numeric($rawStockActual) || (float) $rawStockActual < 0) {
                $erroresFila[] = "Cantidad de stock inválida ({$rawStockActual}). Debe ser un número >= 0.";
            }
            if (!is_numeric($rawStockMinimo) || (float) $rawStockMinimo < 0) {
                $erroresFila[] = "Stock mínimo inválido ({$rawStockMinimo}). Debe ser un número >= 0.";
            }

            $precioVenta = is_numeric($rawPrecioVenta) ? round((float) $rawPrecioVenta, 2) : 0.0;
            $costo = is_numeric($rawCosto) ? round((float) $rawCosto, 2) : 0.0;
            $stockActual = is_numeric($rawStockActual) ? round((float) $rawStockActual, 2) : 0.0;
            $stockMinimo = is_numeric($rawStockMinimo) ? round((float) $rawStockMinimo, 2) : 0.0;

            if ($rawTipoProd === 'PRODUCTO' && $precioVenta <= 0) {
                $advertenciasFila[] = 'El precio de venta es 0 para un producto de venta.';
            }

            // 6. Maneja Inventario
            $rawManejaInv = $normalizedRow['maneja_inventario'] ?? $normalizedRow['inventario'] ?? true;
            if (is_string($rawManejaInv)) {
                $valUpper = mb_strtoupper(trim($rawManejaInv), 'UTF-8');
                $manejaInventario = in_array($valUpper, ['TRUE', '1', 'SI', 'SÍ', 'YES', 'ACTIVO'], true);
            } else {
                $manejaInventario = (bool) $rawManejaInv;
            }
            if ($rawTipoProd === 'SERVICIO') {
                $manejaInventario = false;
            }

            // 7. Resolver Categoría, Marca, Unidad de Medida e Impuesto
            $rawCat = $normalizedRow['categoria_id'] ?? $normalizedRow['categoria'] ?? null;
            $categoriaId = $defaultCategoriaId;
            $categoriaNombre = 'General';
            if ($rawCat !== null && trim((string) $rawCat) !== '') {
                $catFound = is_numeric($rawCat)
                    ? $categorias->firstWhere('id', (int) $rawCat)
                    : $categorias->first(fn ($c) => mb_strtolower($c->nombre, 'UTF-8') === mb_strtolower(trim((string) $rawCat), 'UTF-8'));
                if ($catFound) {
                    $categoriaId = $catFound->id;
                    $categoriaNombre = $catFound->nombre;
                }
            } elseif ($defaultCategoriaId) {
                $categoriaNombre = $categorias->firstWhere('id', $defaultCategoriaId)?->nombre ?? 'General';
            }

            $rawMarca = $normalizedRow['marca_id'] ?? $normalizedRow['marca'] ?? null;
            $marcaId = $defaultMarcaId;
            if ($rawMarca !== null && trim((string) $rawMarca) !== '') {
                $marcaFound = is_numeric($rawMarca)
                    ? $marcas->firstWhere('id', (int) $rawMarca)
                    : $marcas->first(fn ($m) => mb_strtolower($m->nombre, 'UTF-8') === mb_strtolower(trim((string) $rawMarca), 'UTF-8'));
                if ($marcaFound) {
                    $marcaId = $marcaFound->id;
                }
            }

            $rawUnidad = $normalizedRow['unidad_medida_id'] ?? $normalizedRow['unidad_medida'] ?? $normalizedRow['unidad'] ?? null;
            $unidadMedidaId = $defaultUnidadId;
            $unidadAbrev = 'UND';
            if ($rawUnidad !== null && trim((string) $rawUnidad) !== '') {
                $uStr = mb_strtolower(trim((string) $rawUnidad), 'UTF-8');
                $unidadFound = is_numeric($rawUnidad)
                    ? $unidades->firstWhere('id', (int) $rawUnidad)
                    : $unidades->first(fn ($u) => mb_strtolower((string) $u->abreviatura, 'UTF-8') === $uStr || mb_strtolower($u->nombre, 'UTF-8') === $uStr);
                if ($unidadFound) {
                    $unidadMedidaId = $unidadFound->id;
                    $unidadAbrev = $unidadFound->abreviatura ?? $unidadFound->nombre;
                }
            }

            $rawImpuesto = $normalizedRow['impuesto_id'] ?? $normalizedRow['itbis'] ?? $normalizedRow['impuesto'] ?? null;
            $impuestoId = $defaultImpuestoId;
            if ($rawImpuesto !== null && trim((string) $rawImpuesto) !== '') {
                $impFound = is_numeric($rawImpuesto)
                    ? ($impuestos->firstWhere('id', (int) $rawImpuesto) ?? $impuestos->firstWhere('tasa', (float) $rawImpuesto))
                    : $impuestos->first(fn ($i) => str_contains(mb_strtolower($i->nombre, 'UTF-8'), mb_strtolower(trim((string) $rawImpuesto), 'UTF-8')));
                if ($impFound) {
                    $impuestoId = $impFound->id;
                }
            }

            // 8. Verificación de Duplicados (En Archivo y en Base de Datos)
            if (!empty($erroresFila)) {
                $estado = 'ERROR';
            } elseif (isset($nombresEnArchivo[$nombre])) {
                $estado = 'DUPLICADO_ARCHIVO';
                $erroresFila[] = "Nombre duplicado dentro del mismo archivo (repetido en fila {$nombresEnArchivo[$nombre]}).";
            } elseif (!$codigoAutogenerado && isset($codigosEnArchivo[$codigo])) {
                $estado = 'DUPLICADO_ARCHIVO';
                $erroresFila[] = "Código '{$codigo}' duplicado dentro del mismo archivo (repetido en fila {$codigosEnArchivo[$codigo]}).";
            } elseif (isset($nombresEnBd[$nombre])) {
                $estado = 'DUPLICADO_BD';
                $erroresFila[] = "Ya existe un producto con el nombre '{$nombre}' en el sistema.";
            } elseif (!$codigoAutogenerado && isset($codigosEnBd[$codigo])) {
                $estado = 'DUPLICADO_BD';
                $erroresFila[] = "Ya existe un producto con el código '{$codigo}' en el sistema.";
            }

            if ($nombre !== '' && !isset($nombresEnArchivo[$nombre])) {
                $nombresEnArchivo[$nombre] = $numeroFila;
            }
            if ($codigo !== '' && !isset($codigosEnArchivo[$codigo])) {
                $codigosEnArchivo[$codigo] = $numeroFila;
                if (!in_array($codigo, $codigosReservados, true)) {
                    $codigosReservados[] = $codigo;
                }
            }

            if ($estado === 'LISTO') {
                $conteoListos++;
            } elseif ($estado === 'DUPLICADO_BD' || $estado === 'DUPLICADO_ARCHIVO') {
                $conteoDuplicados++;
            } else {
                $conteoErrores++;
            }

            $filasProcesadas[] = [
                'fila'               => $numeroFila,
                'seleccionado'       => $estado === 'LISTO',
                'estado'             => $estado,
                'mensajes'           => array_merge($erroresFila, $advertenciasFila),
                'nombre'             => $nombre,
                'codigo'             => $codigo,
                'codigo_autogenerado'=> $codigoAutogenerado,
                'descripcion'        => $descripcion,
                'categoria_id'       => $categoriaId,
                'categoria_nombre'   => $categoriaNombre,
                'marca_id'           => $marcaId,
                'unidad_medida_id'   => $unidadMedidaId,
                'unidad_abrev'       => $unidadAbrev,
                'impuesto_id'        => $impuestoId,
                'tipo_producto'      => $rawTipoProd,
                'tipo_contable'      => $rawTipoContable,
                'precio_venta'       => $precioVenta,
                'costo'              => $costo,
                'stock_actual'       => $stockActual,
                'stock_minimo'       => $stockMinimo,
                'maneja_inventario'  => $manejaInventario,
            ];
        }

        return [
            'resumen' => [
                'total'      => count($filasProcesadas),
                'listos'     => $conteoListos,
                'duplicados' => $conteoDuplicados,
                'errores'    => $conteoErrores,
            ],
            'filas' => $filasProcesadas,
        ];
    }

    /**
     * Confirma y guarda masivamente la lista de productos validados desde la pantalla de previsualización.
     */
    public function confirmarImportacionMasiva(array $productos): array
    {
        $creados = 0;
        $omitidos = 0;
        $errores = [];
        $codigosReservados = [];

        return DB::transaction(function () use ($productos, &$creados, &$omitidos, &$errores, &$codigosReservados) {
            foreach ($productos as $index => $item) {
                $filaNum = $item['fila'] ?? ($index + 1);
                $nombre = $this->normalizarNombre((string) ($item['nombre'] ?? ''));

                if ($nombre === '') {
                    $errores[] = "Fila {$filaNum}: El nombre del producto está vacío.";
                    continue;
                }

                // Verificar que no exista otro igual en la BD
                $existeNombre = Producto::where('nombre', $nombre)->exists();
                if ($existeNombre) {
                    $omitidos++;
                    $errores[] = "Fila {$filaNum} ({$nombre}): Omitido porque ya existe un producto con el mismo nombre.";
                    continue;
                }

                $rawCodigo = trim((string) ($item['codigo'] ?? ''));
                if ($rawCodigo === '') {
                    $codigo = $this->generarCodigoUnico($nombre, $codigosReservados);
                } else {
                    $codigo = mb_strtoupper($rawCodigo, 'UTF-8');
                    if (Producto::where('codigo', $codigo)->exists()) {
                        // Si el código ya fue tomado, generamos uno nuevo único automáticamente
                        $codigo = $this->generarCodigoUnico($nombre, $codigosReservados);
                    } else {
                        $codigosReservados[] = $codigo;
                    }
                }

                $precioVenta = max(0.0, (float) ($item['precio_venta'] ?? 0));
                $costo = max(0.0, (float) ($item['costo'] ?? 0));
                $stockInicial = max(0.0, (float) ($item['stock_actual'] ?? 0));
                $stockMinimo = max(0.0, (float) ($item['stock_minimo'] ?? 0));
                $tipoProducto = mb_strtoupper(trim((string) ($item['tipo_producto'] ?? 'PRODUCTO')), 'UTF-8') ?: 'PRODUCTO';
                $tipoContable = mb_strtoupper(trim((string) ($item['tipo_contable'] ?? 'INVENTARIO')), 'UTF-8') ?: 'INVENTARIO';
                $manejaInventario = (bool) ($item['maneja_inventario'] ?? true);

                if ($tipoProducto === 'SERVICIO') {
                    $manejaInventario = false;
                    $stockInicial = 0.0;
                }

                try {
                    $producto = Producto::create([
                        'nombre'            => $nombre,
                        'codigo'            => $codigo,
                        'descripcion'       => !empty($item['descripcion']) ? mb_strtoupper(trim((string) $item['descripcion']), 'UTF-8') : null,
                        'categoria_id'      => !empty($item['categoria_id']) ? (int) $item['categoria_id'] : null,
                        'marca_id'          => !empty($item['marca_id']) ? (int) $item['marca_id'] : null,
                        'unidad_medida_id'  => !empty($item['unidad_medida_id']) ? (int) $item['unidad_medida_id'] : null,
                        'impuesto_id'       => !empty($item['impuesto_id']) ? (int) $item['impuesto_id'] : null,
                        'tipo_producto'     => $tipoProducto,
                        'tipo_contable'     => $tipoContable,
                        'precio_venta'      => $precioVenta,
                        'precio_compra'     => $costo,
                        'costo'             => $costo,
                        'stock_actual'      => 0,
                        'stock_minimo'      => $stockMinimo,
                        'maneja_inventario' => $manejaInventario,
                        'activo'            => true,
                    ]);

                    // Si trae cantidad de stock inicial > 0, registramos movimiento en Kardex y asiento contable
                    if ($manejaInventario && $stockInicial > 0) {
                        $invService = $this->getInventarioService();
                        if ($invService) {
                            $invService->registrarAjuste(new RegistrarAjusteDTO(
                                productoId: (int) $producto->id,
                                tipo: TipoMovimientoEnum::ENTRADA,
                                cantidad: $stockInicial,
                                motivo: 'INVENTARIO INICIAL (IMPORTACION MASIVA)'
                            ));
                        } else {
                            $producto->update(['stock_actual' => $stockInicial]);
                        }
                    }

                    $creados++;
                } catch (Exception $e) {
                    $errores[] = "Fila {$filaNum} ({$nombre}): Error al guardar - " . $e->getMessage();
                }
            }

            return [
                'creados'  => $creados,
                'omitidos' => $omitidos,
                'errores'  => $errores,
            ];
        });
    }
}
