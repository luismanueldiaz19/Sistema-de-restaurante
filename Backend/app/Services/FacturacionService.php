<?php

namespace App\Services;

use Illuminate\Support\Facades\DB;
use App\Models\Factura;
use App\Models\FacturaDetalle;
use App\Models\CuentaPorCobrar;
use App\Models\Pago;
use App\Models\PagoCxc;
use App\Models\Producto;
use App\Models\MetodoPago;
use Exception;

class FacturacionService {
    protected $inventoryService;
    protected $contabilidadService;
    protected $bankService;

    public function __construct(
        InventoryService $inventoryService,
        ContabilidadService $contabilidadService,
        BankService $bankService
    ) {
        $this->inventoryService = $inventoryService;
        $this->contabilidadService = $contabilidadService;
        $this->bankService = $bankService;
    }

    public function procesarVenta(array $data, int $usuarioId) {
        return DB::transaction(function () use ($data, $usuarioId) {
            // 🔥 GENERAR NCF
            $secuencia = $this->generarNCF($data['ncf_secuencia_id']);
            $ncf = $secuencia['ncf'];
            $tipoFactura = $secuencia['nombre'];

            $detalles = $data['detalles'];
            $subtotal = 0;
            $itbisTotal = 0;
            $descuentoTotal = 0;
            $detallesCalculados = [];

            // 🧮 CALCULAR TODO PRIMERO
            foreach ($detalles as &$item) {
                // Si no mandan el itbis_porcentaje desde el frontend, buscarlo en BD
                if (!isset($item['itbis_porcentaje']) && !empty($item['producto_id'])) {
                    $producto = Producto::with('impuesto')->find($item['producto_id']);
                    if ($producto && $producto->impuesto) {
                        $item['itbis_porcentaje'] = $producto->impuesto->tasa;
                    } else {
                        $item['itbis_porcentaje'] = 0; // Exento por defecto si no tiene impuesto
                    }
                }

                $calc = $this->calcularLinea($item);
                $subtotal += $calc['baseConDescuento'];
                $descuentoTotal += $calc['descuento'];
                $itbisTotal += $calc['itbis'];

                $detallesCalculados[] = [
                    'item' => $item,
                    'calc' => $calc
                ];
            }

            $total = $subtotal + $itbisTotal;

            // 🔍 BUSCAR SESIÓN DE CAJA ACTIVA
            $sesionActiva = DB::table('caja_sesiones')
                ->where('user_id', $usuarioId)
                ->where('estado', 'abierta')
                ->first();

            // ✅ CREAR FACTURA
            $factura = Factura::create([
                'cliente_id' => $data['cliente_id'],
                'user_id' => $usuarioId,
                'caja_sesion_id' => $sesionActiva ? $sesionActiva->id : null,
                'ncf' => $ncf,
                'tipo_factura' => $tipoFactura,
                'dias_credito' => $data['dias_credito'] ?? 0,
                'nota' => $data['nota'] ?? null,
                'fecha_emision' => $data['fecha_emision'],
                'fecha_vencimiento' => $data['fecha_vencimiento'] ?? now()->addDays($data['dias_credito'] ?? 0)->toDateString(),
                'subtotal' => round($subtotal, 2),
                'descuento_total' => round($descuentoTotal, 2),
                'itbis' => round($itbisTotal, 2),
                'total' => round($total, 2),
                'estado' => 'pendiente',
            ]);

            $costoTotalVenta = 0;

            // ✅ INSERTAR DETALLES
            foreach ($detallesCalculados as $detalle) {
                $item = $detalle['item'];
                $calc = $detalle['calc'];

                // 💰 Calcular costo del producto
                if (!empty($item['producto_id'])) {
                    $producto = Producto::find($item['producto_id']);
                    if ($producto) {
                        $costoUnitario = $producto->costo;
                        $costoTotalVenta += ($costoUnitario * $item['cantidad']);
                    }
                }

                DB::table('factura_detalle')->insert([
                    'factura_id' => $factura->id,
                    'producto_id' => $item['producto_id'] ?? null,
                    'descripcion' => $item['descripcion'],
                    'unidad_medida' => $item['unidad_medida'] ?? null,
                    'cantidad' => $item['cantidad'],
                    'precio' => $item['precio'],
                    'descuento' => round($calc['descuento'], 2),
                    'descuento_porcentaje' => $item['descuento_porcentaje'] ?? 0,
                    'itbis' => round($calc['itbis'], 2),
                    'total' => round($calc['total'], 2),
                    'created_at' => now(),
                    'updated_at' => now(),
                ]);

                // 🔥 DESCONTAR INVENTARIO (Si hay producto_id)
                if (!empty($item['producto_id'])) {
                    $this->inventoryService->procesarVenta($item['producto_id'], $item['cantidad'], $ncf);
                }
            }

            $customConfigs = [];
            $bancoIdAfectado = null;
            $referenciaPago = null;
            $montoDepositado = 0;
            $tienePago = isset($data['pago']) && !is_null($data['pago']);

            // 💳 REGISTRAR PAGO (Si viene en la petición)
            if ($tienePago) {
                $pagoData = $data['pago'];
                $metodoPagoId = $pagoData['metodo_pago_id'] ?? null;
                $referenciaPago = $pagoData['referencia_pago'] ?? null;
                $montoDepositado = $pagoData['monto_pagado'] ?? 0;

                Pago::create([
                    'factura_id' => $factura->id,
                    'user_id' => $usuarioId,
                    'caja_sesion_id' => $sesionActiva ? $sesionActiva->id : null,
                    'monto_pagado' => $pagoData['monto_pagado'],
                    'monto_recibido' => $pagoData['monto_recibido'],
                    'devuelta' => $pagoData['devuelta'] ?? 0,
                    'metodo_pago' => $pagoData['metodo_pago'] ?? 'efectivo',
                    'metodo_pago_id' => $metodoPagoId,
                    'referencia_pago' => $referenciaPago,
                    'fecha_pago' => now(),
                ]);

                if ($metodoPagoId) {
                    $metodo = MetodoPago::find($metodoPagoId);
                    if ($metodo) {
                        if ($metodo->catalogo_cuenta_id) {
                            $customConfigs['venta_efectivo_debe'] = $metodo->catalogo_cuenta_id;
                        }
                        if ($metodo->bank_account_id) {
                            $bancoIdAfectado = $metodo->bank_account_id;
                        }
                    }
                }

                // Si el pago cubre el total, marcar factura como pagada
                if ($pagoData['monto_pagado'] >= $total - 0.01) {
                    $factura->update(['estado' => 'pagada']);
                }
            }

            // =====================================================================
            // PASO 1: REGISTRAR LA DEUDA (CUENTA POR COBRAR) Y EL ASIENTO DE VENTA
            // =====================================================================
            // NOTA CONTABLE: Toda factura (sea a crédito o al contado) genera primero 
            // una "Cuenta por Cobrar" (CxC). Esto permite estandarizar el proceso y 
            // que todas las facturas pasen por el subdiario de CxC. Si la venta es 
            // al contado ($tienePago), la deuda nace y se liquida el mismo día, 
            // por lo que su balance_pendiente queda en 0 y su estado en 'PAGADA'.
            $cxc = CuentaPorCobrar::create([
                'cliente_id' => $data['cliente_id'],
                'factura_id' => $factura->id,
                'monto_original' => $total,
                'balance_pendiente' => $tienePago ? 0 : $total,
                'fecha_emision' => now()->toDateString(),
                'fecha_vencimiento' => now()->addDays($data['dias_credito'] ?? 30)->toDateString(),
                'estado' => $tienePago ? 'PAGADA' : 'PENDIENTE',
                'descripcion' => "Factura NCF: $ncf"
            ]);

            // ASIENTO #1 (VENTA): 
            // Siempre usamos la estrategia 'venta_credito', la cual hace lo siguiente:
            // - DÉBITO a: Cuentas por Cobrar Clientes (aumenta el derecho a cobro)
            // - CRÉDITO a: Ingresos por Ventas (reconoce el ingreso)
            // - CRÉDITO a: ITBIS por Pagar (reconoce el impuesto a pagar)
            // - (También afecta Costo e Inventario si aplica)
            $asientoContable = $this->contabilidadService -> registrarAsientoAuto(
                'venta_credito',
                round($subtotal, 2),
                round($itbisTotal, 2),
                round($total, 2),
                $ncf,
                "Venta - Factura NCF $ncf",
                $usuarioId,
                $customConfigs,
                round($costoTotalVenta, 2)
            );

            $asientoPago = null;

            // =====================================================================
            // PASO 2: REGISTRAR LA ENTRADA DE EFECTIVO/BANCO (SI FUE AL CONTADO)
            // =====================================================================
            // NOTA CONTABLE: Si el cliente pagó inmediatamente (Venta al Contado), 
            // procedemos a registrar el recibo de caja y el asiento de cobro.
            if ($tienePago) {
                
                $pagoData = $data['pago'];
                
                $pagoCxc = PagoCxc::create([
                    'cxc_id' => $cxc->id,
                    'monto_pagado' => $pagoData['monto_pagado'],
                    'fecha_pago' => now()->toDateString(),
                    'metodo_pago' => strtoupper($pagoData['metodo_pago'] ?? 'EFECTIVO'),
                    'referencia' => $referenciaPago,
                    'cuenta_destino_id' => $customConfigs['venta_efectivo_debe'] ?? 1,
                    'usuario_id' => $usuarioId,
                ]);

                if (isset($customConfigs['venta_efectivo_debe'])) {
                    $customConfigs['pago_cxc_efectivo_debe'] = $customConfigs['venta_efectivo_debe'];
                }

                // ASIENTO #2 (PAGO/COBRO):
                // Usamos la estrategia 'pago_cxc', la cual hace lo siguiente:
                // - DÉBITO a: Caja General o Banco (entra el dinero real a nuestra cuenta)
                // - CRÉDITO a: Cuentas por Cobrar Clientes (liquida la deuda que se creó en el Paso 1)
                $asientoPago = $this->contabilidadService->registrarAsientoAuto(
                    'pago_cxc',
                    0, 0, $total,
                    $ncf,
                    "Cobro de Factura NCF: $ncf",
                    $usuarioId,
                    $customConfigs
                );

                if ($asientoPago) {
                    $pagoCxc->update(['asiento_id' => $asientoPago->id]);
                }
            }

            // 🏦 REGISTRAR TRANSACCIÓN BANCARIA (Si aplica)
            if ($bancoIdAfectado) {
                $asientoId = $asientoPago ? $asientoPago->id : ($asientoContable ? $asientoContable->id : null);
                $this->bankService->registrarTransaccion(
                    $bancoIdAfectado,
                    'deposit',
                    $montoDepositado,
                    $referenciaPago,
                    "Cobro de Factura NCF: $ncf",
                    $asientoId
                );
            }

            return [
                'factura_id' => $factura->id,
                'ncf' => $ncf,
                'tipo_factura' => $tipoFactura
            ];
        });
    }

    private function generarNCF($id) {
        $sec = DB::table('ncf_secuencias')
            ->where('id', $id)
            ->lockForUpdate()
            ->first();

        if (!$sec || !$sec->activo) {
            throw new Exception("Secuencia no válida");
        }

        $nuevo = $sec->actual + 1;

        if ($nuevo > $sec->rango_fin) {
            throw new Exception("Secuencia agotada");
        }

        DB::table('ncf_secuencias')
            ->where('id', $id)
            ->update(['actual' => $nuevo]);

        $ncf = $sec->prefijo . $sec->tipo . str_pad($nuevo, 10, '0', STR_PAD_LEFT);

        return [
            'ncf' => $ncf,
            'tipo' => $sec->tipo,
            'nombre' => $sec->nombre
        ];
    }

    private function calcularLinea($item)
    {
        $cantidad = $item['cantidad'];
        $precio = $item['precio']; // ya incluye ITBIS

        $itbis_porcentaje = isset($item['itbis_porcentaje']) ? $item['itbis_porcentaje'] : 18;
        $tasaDecimal = ($itbis_porcentaje <= 1 && $itbis_porcentaje > 0) ? $itbis_porcentaje : ($itbis_porcentaje / 100);

        $linea = $cantidad * $precio;
        $base = $linea / (1 + $tasaDecimal);
        $descuento = $item['descuento'] ?? 0;

        if (!empty($item['descuento_porcentaje'])) {
            $descuento = $base * ($item['descuento_porcentaje'] / 100);
        }

        if ($descuento > $base) {
            throw new Exception("El descuento no puede ser mayor que el precio base");
        }

        if ($descuento < 0) {
            throw new Exception("El descuento no puede ser negativo");
        }

        $baseConDescuento = $base - $descuento;
        $itbis = $baseConDescuento * $tasaDecimal;
        $total = $baseConDescuento + $itbis;

        return [
            'base' => $base,
            'descuento' => $descuento,
            'baseConDescuento' => $baseConDescuento,
            'itbis' => $itbis,
            'total' => $total
        ];
    }
}
