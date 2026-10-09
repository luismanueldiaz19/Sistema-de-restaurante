<?php

declare(strict_types=1);

namespace App\Modules\CuentaPorPagar\Services;

use App\Modules\CuentaPorPagar\DTOs\RegistrarPagoDTO;
use App\Modules\CuentaPorPagar\Exceptions\CuentaPorPagarException;
use App\Models\CuentaPorPagar;
use App\Models\PagoCompra;
use App\Models\MetodoPago;
use App\Modules\Contabilidad\Services\ContabilidadService;
use App\Services\BankService;
use Illuminate\Support\Facades\DB;
use Illuminate\Database\Eloquent\Collection;

class CuentaPorPagarService
{
    public function __construct(
        private readonly ContabilidadService $contabilidadService,
        private readonly BankService $bankService
    ) {}

    public function getPending(): Collection
    {
        return CuentaPorPagar::with(['proveedor', 'compra.detalles.producto'])
            ->orderBy('fecha_vencimiento', 'asc')
            ->get();
    }

    public function registrarPago(RegistrarPagoDTO $dto): array
    {
        $cxp = CuentaPorPagar::with('compra')->findOrFail($dto->cxp_id);

        if ($dto->monto_pagado > $cxp->balance_pendiente) {
            throw new CuentaPorPagarException('El monto pagado no puede superar el balance pendiente de la cuenta por pagar.');
        }

        return DB::transaction(function () use ($dto, $cxp) {
            $metodo = MetodoPago::findOrFail($dto->metodo_pago_id);
            $cuentaOrigenId = $metodo->catalogo_cuenta_id ?? 1; // Fallback
            $bancoIdAfectado = $metodo->bank_account_id;

            // Registrar el pago
            $pago = PagoCompra::create([
                'cxp_id' => $cxp->id,
                'monto_pagado' => $dto->monto_pagado,
                'fecha_pago' => $dto->fecha_pago,
                'metodo_pago_id' => $dto->metodo_pago_id,
                'referencia' => $dto->referencia,
                'cuenta_origen_id' => $cuentaOrigenId,
                'usuario_id' => auth()->id() ?? 1,
            ]);

            // Actualizar Balance CxP
            $nuevoBalance = $cxp->balance_pendiente - $dto->monto_pagado;
            
            $estado = 'PENDIENTE';
            if ($nuevoBalance <= 0) {
                $estado = 'PAGADA';
                $nuevoBalance = 0;
            } elseif ($nuevoBalance < $cxp->monto_original) {
                $estado = 'PARCIAL';
            }

            $cxp->update([
                'balance_pendiente' => $nuevoBalance,
                'estado' => $estado,
            ]);

            // Si se pagó la CxP entera, actualizar estado de la Compra a PAGADA
            if ($estado === 'PAGADA' && $cxp->compra) {
                $cxp->compra->update(['estado' => 'PAGADA']);
            }

            // Registrar Asiento Contable del Pago
            $numeroFactura = $cxp->compra->numero_factura_proveedor ?? 'N/A';
            $asientoPago = $this->contabilidadService->registrarAsientoAuto(
                'pago_compra',
                0, 0, $dto->monto_pagado,
                "PAGO-CXP-{$pago->id}",
                "Abono a CxP de Compra Fac: " . $numeroFactura,
                auth()->id() ?? 1,
                ['pago_compra_efectivo_haber' => $cuentaOrigenId]
            );

            if ($asientoPago) {
                $pago->update(['asiento_id' => $asientoPago->id]);
            }

            // REGISTRAR TRANSACCIÓN BANCARIA (Si aplica)
            if ($bancoIdAfectado) {
                $asientoId = $asientoPago ? $asientoPago->id : null;
                $this->bankService->registrarTransaccion(
                    $bancoIdAfectado,
                    'withdrawal', // Retiro por pago de cuenta por pagar
                    $dto->monto_pagado,
                    $dto->referencia,
                    "Abono a CxP de Compra Fac: " . $numeroFactura,
                    $asientoId
                );
            }

            return $pago->load('cuentaPorPagar')->toArray();
        });
    }

    public function getHistorialPagos(): Collection
    {
        return PagoCompra::with([
            'cuentaPorPagar.proveedor',
            'cuentaPorPagar.compra',
            'cuentaOrigen',
            'usuario'
        ])->orderBy('fecha_pago', 'desc')->get();
    }
}
