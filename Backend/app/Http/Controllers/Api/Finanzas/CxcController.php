<?php

namespace App\Http\Controllers\Api\Finanzas;

use App\Http\Controllers\Controller;
use App\Models\CuentaPorCobrar;
use App\Models\PagoCxc;
use App\Services\ContabilidadService;
use App\Services\CxcService;
use App\Http\Requests\Api\Finanzas\RegistrarCobroRequest;
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

    public function registrarPago(RegistrarCobroRequest $request, $id, CxcService $cxcService)
    {
        $cxc = CuentaPorCobrar::findOrFail($id);

        try {
            $pago = $cxcService->registrarCobro($cxc, $request->validated(), auth()->id() ?? 1);
            return response()->json(['message' => 'Cobro registrado con éxito', 'pago' => $pago]);
        } catch (Exception $e) {
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

