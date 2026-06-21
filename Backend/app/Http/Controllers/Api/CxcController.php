<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\CuentaPorCobrar;
use App\Models\PagoCxc;
use App\Services\ContabilidadService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Exception;

class CxcController extends Controller
{
    protected $contabilidadService;

    public function __construct(ContabilidadService $contabilidadService)
    {
        $this->contabilidadService = $contabilidadService;
    }

    public function index()
    {
        // Get all unpaid or partially paid CxC
        $cxcs = CuentaPorCobrar::with(['cliente', 'factura.detalles.producto'])
            ->orderBy('fecha_emision', 'desc')
            ->get();
            
        return response()->json($cxcs);
    }

    public function registrarPago(Request $request, $id)
    {
        $cxc = CuentaPorCobrar::findOrFail($id);

        $validated = $request->validate([
            'monto_pagado' => 'required|numeric|min:0.01|max:'.$cxc->balance_pendiente,
            'fecha_pago' => 'required|date',
            'metodo_pago' => 'required|in:EFECTIVO,TRANSFERENCIA,CHEQUE',
            'cuenta_destino_id' => 'required|exists:catalogo_cuentas,id', // Bank or Cash account where money goes
            'referencia' => 'nullable|string',
        ]);

        DB::beginTransaction();
        try {
            // Registrar el pago
            $pago = PagoCxc::create([
                'cxc_id' => $cxc->id,
                'monto_pagado' => $validated['monto_pagado'],
                'fecha_pago' => $validated['fecha_pago'],
                'metodo_pago' => $validated['metodo_pago'],
                'referencia' => $validated['referencia'] ?? null,
                'cuenta_destino_id' => $validated['cuenta_destino_id'],
                'usuario_id' => auth()->id() ?? 1,
            ]);

            // Actualizar Balance CxC
            $nuevoBalance = $cxc->balance_pendiente - $validated['monto_pagado'];
            $estado = 'PENDIENTE';
            if ($nuevoBalance <= 0) {
                $estado = 'PAGADA';
                $nuevoBalance = 0;
            } elseif ($nuevoBalance < $cxc->monto_original) {
                $estado = 'PARCIAL';
            }

            $cxc->update([
                'balance_pendiente' => $nuevoBalance,
                'estado' => $estado,
            ]);

            // Si se pagó la CxC entera, actualizar estado de la Factura a PAGADA
            if ($estado === 'PAGADA' && $cxc->factura) {
                $cxc->factura->update(['estado' => 'pagada']);
            }

            // Registrar Asiento Contable del Pago
            $asientoPago = $this->contabilidadService->registrarAsientoAuto(
                'pago_cxc',
                0, 0, $validated['monto_pagado'],
                $cxc->factura ? $cxc->factura->ncf : "COBRO-CXC-{$pago->id}",
                "Cobro de CxC Factura: " . ($cxc->factura->id ?? 'N/A'),
                auth()->id() ?? 1,
                ['pago_cxc_efectivo_debe' => $validated['cuenta_destino_id']]
            );

            if ($asientoPago) {
                $pago->update(['asiento_id' => $asientoPago->id]);
            }

            DB::commit();
            return response()->json(['message' => 'Cobro registrado con éxito', 'pago' => $pago]);
        } catch (Exception $e) {
            DB::rollBack();
            return response()->json(['error' => 'Error al registrar el cobro: ' . $e->getMessage()], 500);
        }
    }

    public function historialPagos()
    {
        $pagos = PagoCxc::with([
            'cuentaPorCobrar.cliente',
            'cuentaPorCobrar.factura',
            'cuentaDestino',
            'usuario'
        ])->orderBy('fecha_pago', 'desc')->get();

        return response()->json($pagos);
    }
}
