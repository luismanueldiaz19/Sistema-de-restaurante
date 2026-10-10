<?php

declare(strict_types=1);

namespace App\Modules\Compra\Services;

use App\Modules\Compra\DTOs\CreateCompraDTO;
use App\Modules\Compra\Exceptions\CompraException;
use App\Modules\Compra\Enums\CompraTipoEnum;
use App\Modules\Compra\Enums\CompraEstadoEnum;
use App\Models\Compra;
use App\Models\CompraDetalle;
use App\Models\CuentaPorPagar;
use App\Models\PagoCompra;
use App\Models\Producto;
use App\Models\Proveedor;
use App\Modules\Contabilidad\Services\ContabilidadService;
use App\Services\BankService;
use Illuminate\Support\Facades\DB;
use App\Models\MetodoPago;

class CompraService
{
    public function __construct(
        private readonly ContabilidadService $contabilidadService,
        private readonly BankService $bankService
    ) {}

    public function create(CreateCompraDTO $dto): array {
        return DB::transaction(function () use ($dto) {
            // Verificar idempotencia: Si ya existe esta factura para este proveedor, no duplicar.
            $compraExistente = Compra::with('detalles')
                ->where('proveedor_id', $dto->proveedor_id)
                ->where('numero_factura_proveedor', $dto->numero_factura_proveedor)
                ->first();

            if ($compraExistente) {
                return $compraExistente->toArray();
            }

            $subtotal  = 0;
            $impuestos = 0;
            $total     = 0;

            $detallesProcesados = [];

            foreach ($dto->detalles as $d) {
                // Incorporar el factor de conversión en el stock si corresponde
                $factor = isset($d['factor_conversion']) ? (float) $d['factor_conversion'] : 1.0;
                $cantidadFacturada = (float) $d['cantidad'];
                $costoUnitario = (float) $d['costo_unitario'];
                $impuestoMonto = (float) $d['impuesto_monto'];

                $d_subtotal = $cantidadFacturada * $costoUnitario;
                $d_total    = $d_subtotal + $impuestoMonto;

                $d['subtotal'] = $d_subtotal;
                $d['total']    = $d_total;

                $subtotal  += $d_subtotal;
                $impuestos += $impuestoMonto;
                $total     += $d_total;

                $detallesProcesados[] = $d;
            }

            // Verificar si el proveedor es informal para generar E41 y aplicar retención
            // $proveedor = Proveedor::findOrFail($dto->proveedor_id);
            // $esInformal = (bool) $proveedor->es_informal;
            $esInformal = false; // Comentado temporalmente
            $ncfFinal = $dto->ncf;

            /*
            if ($esInformal) {
                // Buscar secuencia E41
                $sec = DB::table('ncf_secuencias')->where('tipo', '41')->lockForUpdate()->first();
                if ($sec) {
                    $nuevo = $sec->actual + 1;
                    DB::table('ncf_secuencias')->where('id', $sec->id)->update(['actual' => $nuevo]);
                    // E41 requiere 10 digitos de secuencia para completar 13 chars (E41 + 10)
                    $ncfFinal = 'E41' . str_pad((string)$nuevo, 10, '0', STR_PAD_LEFT);
                }
            }
            */
            // Crear Compra
            $estado = $dto->tipo_compra === CompraTipoEnum::CONTADO ? CompraEstadoEnum::PAGADA->value : CompraEstadoEnum::PENDIENTE->value;

            $compra = Compra::create([
                'proveedor_id'              => $dto->proveedor_id,
                'numero_factura_proveedor'  => $dto->numero_factura_proveedor,
                'ncf'                       => $ncfFinal,
                'fecha_compra'              => $dto->fecha_compra,
                'fecha_vencimiento'         => $dto->fecha_vencimiento,
                'tipo_compra'               => $dto->tipo_compra->value,
                'subtotal'                  => $subtotal,
                'impuestos'                 => $impuestos,
                'total'                     => $total,
                'estado'                    => $estado,
                'usuario_id'                => auth()->id() ?? 1,
                'notas'                     => $dto->notas,
            ]);

            // Guardar Detalles y actualizar stock de productos
            foreach ($detallesProcesados as $d) {
                CompraDetalle::create([
                    'compra_id'          => $compra->id,
                    'producto_id'        => $d['producto_id'] ?? null,
                    'descripcion'        => $d['descripcion'] ?? null,
                    'cuenta_contable_id' => $d['cuenta_contable_id'] ?? null,
                    'presentacion'       => $d['presentacion'] ?? null,
                    'factor_conversion'  => $d['factor_conversion'] ?? 1,
                    'cantidad'           => $d['cantidad'],
                    'costo_unitario'     => $d['costo_unitario'],
                    'subtotal'           => $d['subtotal'],
                    'impuesto_monto'     => $d['impuesto_monto'],
                    'total'              => $d['total'],
                ]);

                /* OMITIDO TEMPORALMENTE HASTA CREAR MODULO DE INVENTARIO
                if (!empty($d['producto_id'])) {
                    $producto = Producto::find($d['producto_id']);
                    if ($producto && $producto->maneja_inventario) {
                        $stockAnterior = $producto->stock_actual;
                        
                        // Aquí sumamos considerando el factor de conversión
                        $cantidadReal = (float)$d['cantidad'] * (float)($d['factor_conversion'] ?? 1);
                        $nuevoStock = $stockAnterior + $cantidadReal;
                        
                        $costoAnterior = $producto->costo;
                        // Costo ponderado: costo unitario / factor para tener el costo por unidad mínima
                        $costoNuevoUnidadMinima = (float)$d['costo_unitario'] / (float)($d['factor_conversion'] ?? 1);

                        $costoPromedio = 0;
                        if ($nuevoStock > 0) {
                            $costoPromedio = (($stockAnterior * $costoAnterior) + ($cantidadReal * $costoNuevoUnidadMinima)) / $nuevoStock;
                        } else {
                            $costoPromedio = $costoNuevoUnidadMinima;
                        }

                        $producto->stock_actual = $nuevoStock;
                        $producto->costo = $costoPromedio;
                        $producto->save();
                    }
                }
                */
            }

            /* OMITIDO TEMPORALMENTE HASTA CREAR MODULOS DE CXP, BANCOS Y CONTABILIDAD
            // Crear siempre la CXP, porque el pago depende de ella
            $cxp = CuentaPorPagar::create([
                'proveedor_id'      => $dto->proveedor_id,
                'compra_id'         => $compra->id,
                'monto_original'    => $total,
                'balance_pendiente' => $dto->tipo_compra === CompraTipoEnum::CREDITO ? $total : 0,
                'fecha_vencimiento' => $dto->fecha_vencimiento ?? $dto->fecha_compra,
                'estado'            => $dto->tipo_compra === CompraTipoEnum::CREDITO ? 'PENDIENTE' : 'PAGADA',
            ]);

            if ($dto->tipo_compra === CompraTipoEnum::CONTADO) {
                // Es CONTADO, procesar pago inmediato
                if (!$dto->metodo_pago_id) {
                    throw new CompraException('El método de pago es requerido para compras al contado.');
                }

                $metodo = \App\Models\MetodoPago::find($dto->metodo_pago_id);
                if (!$metodo || !$metodo->catalogo_cuenta_id) {
                    throw new CompraException('El método de pago no tiene una cuenta contable asociada.');
                }

                $pago = PagoCompra::create([
                    'cxp_id'           => $cxp->id,
                    'monto_pagado'     => $total,
                    'fecha_pago'       => $dto->fecha_compra,
                    'metodo_pago_id'   => $dto->metodo_pago_id,
                    'referencia'       => $dto->referencia_pago,
                    'cuenta_origen_id' => $metodo->catalogo_cuenta_id,
                    'usuario_id'       => auth()->id() ?? 1,
                ]);

                if ($this->bankService) {
                    $this->bankService->registrarTransaccion(
                        cuentaId: $dto->metodo_pago_id,
                        tipo: 'retiro',
                        monto: (float) $total,
                        fecha: $dto->fecha_compra,
                        descripcion: "Pago inmediato Factura Prov. {$dto->numero_factura_proveedor}",
                        referencia: $pago->id
                    );
                }
            }

            // Asiento contable
            try {
                $asientoId = $this->contabilidadService->registrarAsientoCompra($compra->id);
                if ($asientoId) {
                    $compra->asiento_id = $asientoId;
                    $compra->save();
                }
            } catch (\Exception $e) {
                // Log and continue
            }
            */

            // --- LÓGICA DE CONTADO VS CRÉDITO ---
            if ($dto->tipo_compra === CompraTipoEnum::CONTADO) {
                // Compra al contado: No se registra CxP. Se registra el pago directamente.
                if ($dto->metodo_pago_id) {
                    $metodo = MetodoPago::find($dto->metodo_pago_id);
                    $cuentaOrigenId = $metodo ? $metodo->catalogo_cuenta_id : 1;

                    // Crear el recibo de pago asociado a la compra
                    $pago = PagoCompra::create([
                        'compra_id' => $compra->id,
                        'monto_pagado' => $total,
                        'fecha_pago' => $dto->fecha_compra,
                        'metodo_pago_id' => $dto->metodo_pago_id,
                        'referencia' => $dto->referencia_pago ?? "Pago Fac. {$dto->numero_factura_proveedor}",
                        'cuenta_origen_id' => $cuentaOrigenId,
                        'usuario_id' => auth()->id() ?? 1,
                    ]);

                    if ($metodo && $metodo->bank_account_id && $this->bankService) {
                        $this->bankService->registrarTransaccion(
                            $metodo->bank_account_id,
                            'withdrawal',
                            (float) $total,
                            $dto->referencia_pago ?? "Pago Fac. {$dto->numero_factura_proveedor}",
                            "Pago inmediato Factura Prov. {$dto->numero_factura_proveedor}"
                        );
                    }
                }
            } else {
                // Compra al crédito: Se registra la CxP. No hay pago inmediato.
                $cxp = CuentaPorPagar::create([
                    'proveedor_id'      => $dto->proveedor_id,
                    'compra_id'         => $compra->id,
                    'monto_original'    => $total,
                    'balance_pendiente' => $total,
                    'fecha_vencimiento' => $dto->fecha_vencimiento ?? $dto->fecha_compra,
                    'estado'            => 'PENDIENTE',
                ]);
            }

            /* Comentado temporalmente para probar CxP y Pagos primero
            // Asiento contable
            try {
                if ($this->contabilidadService) {
                    $customConfigs = [
                        'es_informal' => $esInformal,
                        'detalles' => $detallesProcesados
                    ];

                    $asiento = $this->contabilidadService->registrarAsientoAuto(
                        new \App\Modules\Contabilidad\DTOs\RegistrarAsientoDTO(
                            'compra_inventario',
                            $subtotal,
                            $impuestos,
                            $total,
                            $ncfFinal ?? 'S/N',
                            "Compra - Factura Prov: " . ($dto->numero_factura_proveedor ?? 'S/N'),
                            auth()->id() ?? 1,
                            $customConfigs
                        )
                    );

                    if ($asiento) {
                        $compra->asiento_id = $asiento->id;
                        $compra->save();
                    }

                    // Si fue al contado, asentar el pago
                    if ($dto->tipo_compra === CompraTipoEnum::CONTADO && $dto->metodo_pago_id && isset($pago) && isset($cuentaOrigenId)) {
                        $asientoPago = $this->contabilidadService->registrarAsientoAuto(
                            new \App\Modules\Contabilidad\DTOs\RegistrarAsientoDTO(
                                'pago_compra',
                                0, 0, $total,
                                "PAGO-COMPRA-{$compra->id}",
                                "Pago inmediato de Compra Fac: " . ($dto->numero_factura_proveedor ?? 'S/N'),
                                auth()->id() ?? 1,
                                ['pago_compra_efectivo_haber' => $cuentaOrigenId]
                            )
                        );
                        if ($asientoPago) {
                            $pago->asiento_id = $asientoPago->id;
                            $pago->save();
                        }
                    }
                }
            } catch (\Exception $e) {
                // Log and continue
            }
            */
            // ----------------------------------------------------

            $compra->load('detalles');
            return $compra->toArray();
        });
    }
}
