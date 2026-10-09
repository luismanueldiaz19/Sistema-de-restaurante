<?php
declare(strict_types=1);

namespace App\Modules\CuentaPorCobrar\Services;

use App\Modules\CuentaPorCobrar\DTOs\RegistrarCobroDTO;
use App\Modules\CuentaPorCobrar\Exceptions\CuentaPorCobrarException;
use App\Models\CuentaPorCobrar;
use App\Models\PagoCxc;
use App\Models\MetodoPago;
use App\Modules\Contabilidad\Services\ContabilidadService;
use App\Services\BankService;
use Illuminate\Support\Facades\DB;
use Illuminate\Database\Eloquent\Collection;

class CuentaPorCobrarService
{
    public function __construct(
        private readonly ContabilidadService $contabilidadService,
        private readonly BankService $bankService
    ) {}

    public function getPending(): Collection
    {
        return CuentaPorCobrar::with(['cliente', 'factura.detalles.producto'])
            ->orderBy('fecha_emision', 'desc')
            ->get();
    }

    public function registrarCobro(RegistrarCobroDTO $dto): array
    {
        $cxc = CuentaPorCobrar::with('factura')->findOrFail($dto->cxc_id);

        if ($dto->monto_pagado > $cxc->balance_pendiente) {
            throw new CuentaPorCobrarException("El monto a pagar ({$dto->monto_pagado}) supera el balance pendiente ({$cxc->balance_pendiente})");
        }

        return DB::transaction(function () use ($dto, $cxc) {
            // 1. OBTENER CONFIGURACIÓN DEL MÉTODO DE PAGO
            $metodo = MetodoPago::findOrFail($dto->metodo_pago_id);
            $nombreMetodo = strtoupper($metodo->nombre);
            
            $cuentaDestinoId = $metodo->catalogo_cuenta_id;
            $bancoIdAfectado = $metodo->bank_account_id;

            if (!$cuentaDestinoId) {
                throw new CuentaPorCobrarException("El método de pago '{$nombreMetodo}' no tiene una cuenta contable configurada.");
            }

            // 2. REGISTRAR EL PAGO EN PAGO_CXC
            $pago = PagoCxc::create([
                'cxc_id'            => $cxc->id,
                'monto_pagado'      => $dto->monto_pagado,
                'fecha_pago'        => $dto->fecha_pago,
                'metodo_pago'       => $nombreMetodo,
                'referencia'        => $dto->referencia,
                'cuenta_destino_id' => $cuentaDestinoId,
                'usuario_id'        => auth()->id() ?? 1,
            ]);

            // 3. ACTUALIZAR EL BALANCE Y ESTADO DE LA CXC
            $nuevoBalance = round($cxc->balance_pendiente - $dto->monto_pagado, 2);
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
                0, 0, $dto->monto_pagado,
                $ncfFactura,
                "Cobro de CxC Factura: {$facturaId}",
                auth()->id() ?? 1,
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
                    $dto->monto_pagado,
                    $dto->referencia,
                    "Cobro de CxC Factura: {$ncfFactura}",
                    $asientoPago ? $asientoPago->id : null
                );
            }

            return $pago->load('cuentaPorCobrar')->toArray();
        });
    }

    public function getHistorialPagos(): Collection
    {
        return PagoCxc::with([
            'cuentaPorCobrar.cliente',
            'cuentaPorCobrar.factura',
            'cuentaDestino',
            'usuario'
        ])->orderBy('fecha_pago', 'desc')->get();
    }
}
