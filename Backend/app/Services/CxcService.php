<?php

namespace App\Services;

use App\Models\CuentaPorCobrar;
use App\Models\PagoCxc;
use App\Models\MetodoPago;
use Illuminate\Support\Facades\DB;
use Exception;

class CxcService {
    protected $contabilidadService;
    protected $bankService;

    public function __construct(ContabilidadService $contabilidadService, BankService $bankService) {
        $this->contabilidadService = $contabilidadService;
        $this->bankService = $bankService;
    }

    public function registrarCobro(CuentaPorCobrar $cxc, array $data, int $usuarioId) {
        return DB::transaction(function () use ($cxc, $data, $usuarioId) {
            $montoPagado = $data['monto_pagado'];
            $metodoPagoId = $data['metodo_pago_id'];
            $fechaPago = $data['fecha_pago'];
            $referencia = $data['referencia'] ?? null;

            if ($montoPagado > $cxc->balance_pendiente) {
                throw new Exception("El monto a pagar ($montoPagado) supera el balance pendiente ($cxc->balance_pendiente)");
            }

            // 1. OBTENER CONFIGURACIÓN DEL MÉTODO DE PAGO
            $metodo = MetodoPago::findOrFail($metodoPagoId);
            $nombreMetodo = strtoupper($metodo->nombre);
            
            $cuentaDestinoId = $metodo->catalogo_cuenta_id;
            $bancoIdAfectado = $metodo->bank_account_id;

            if (!$cuentaDestinoId) {
                throw new Exception("El método de pago '$nombreMetodo' no tiene una cuenta contable configurada.");
            }

            // 2. REGISTRAR EL PAGO EN PAGO_CXC
            $pago = PagoCxc::create([
                'cxc_id'            => $cxc->id,
                'monto_pagado'      => $montoPagado,
                'fecha_pago'        => $fechaPago,
                'metodo_pago'       => $nombreMetodo,
                'referencia'        => $referencia,
                'cuenta_destino_id' => $cuentaDestinoId,
                'usuario_id'        => $usuarioId,
            ]);

            // 3. ACTUALIZAR EL BALANCE Y ESTADO DE LA CXC
            $nuevoBalance = round($cxc->balance_pendiente - $montoPagado, 2);
            $estado = 'PENDIENTE';
            
            if ($nuevoBalance <= 0) {
                $estado = 'PAGADA';
                $nuevoBalance = 0;
            } elseif ($nuevoBalance < $cxc->monto_original) {
                $estado = 'PARCIAL';
            }

            $cxc->update([
                'balance_pendiente' => $nuevoBalance,
                'estado'            => $estado,
            ]);

            // Si se pagó completa, marcar factura relacionada como PAGADA
            if ($estado === 'PAGADA' && $cxc->factura) {
                $cxc->factura->update(['estado' => 'pagada']);
            }

            $ncfFactura = $cxc->factura ? $cxc->factura->ncf : "COBRO-CXC-{$pago->id}";
            $facturaId = $cxc->factura ? $cxc->factura->id : 'N/A';

            // 4. REGISTRAR ASIENTO CONTABLE DEL PAGO
            $customConfigs = [
                'pago_cxc_efectivo_debe' => $cuentaDestinoId
            ];

            $asientoPago = $this->contabilidadService->registrarAsientoAuto(
                'pago_cxc',
                0, 0, $montoPagado,
                $ncfFactura,
                "Cobro de CxC Factura: $facturaId",
                $usuarioId,
                $customConfigs
            );

            if ($asientoPago) {
                $pago->update(['asiento_id' => $asientoPago->id]);
            }

            // 5. REGISTRAR TRANSACCIÓN BANCARIA (Si aplica)
            if ($bancoIdAfectado) {
                $this->bankService->registrarTransaccion(
                    $bancoIdAfectado,
                    'deposit',
                    $montoPagado,
                    $referencia,
                    "Cobro de CxC Factura: $ncfFactura",
                    $asientoPago ? $asientoPago->id : null
                );
            }

            return $pago;
        });
    }
}
