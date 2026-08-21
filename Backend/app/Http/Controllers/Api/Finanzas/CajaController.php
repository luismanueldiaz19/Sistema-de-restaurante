<?php

namespace App\Http\Controllers\Api\Finanzas;

use App\Http\Controllers\Controller;
use App\Services\CajaService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;
use App\Models\Caja;
use App\Models\Turno;
use Exception;

class CajaController extends Controller
{
    protected $cajaService;

    public function __construct(CajaService $cajaService)
    {
        $this->cajaService = $cajaService;
    }

    public function index()
    {
        return response()->json([
            'status' => true,
            'data' => Caja::where('activa', true)->get()
        ]);
    }

    public function turnos()
    {
        return response()->json([
            'status' => true,
            'data' => Turno::all()
        ]);
    }

    /**
     * Obtener el estado actual de la caja para el usuario autenticado
     */
    public function estadoActual()
    {
        $sesion = $this->cajaService->getSesionActiva(auth()->id());

        return response()->json([
            'status' => true,
            'data' => $sesion
        ]);
    }

    /**
     * Abrir caja
     */
    public function abrir(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'caja_id' => 'required|exists:cajas,id',
            'turno_id' => 'required|exists:turnos,id',
            'monto_inicial' => 'required|numeric|min:0',
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        try {
            $data = $request->all();
            $data['user_id'] = auth()->id();

            $sesion = $this->cajaService->abrirCaja($data);
            $sesion->load(['caja', 'turno']);

            return response()->json([
                'message' => 'Caja abierta correctamente',
                'data' => $sesion
            ], 201);
        } catch (Exception $e) {
            return response()->json(['message' => $e->getMessage()], 400);
        }
    }

    /**
     * Obtener resumen antes de cerrar
     */
    public function resumen()
    {
        try {
            $sesionActiva = $this->cajaService->getSesionActiva(auth()->id());

            if (!$sesionActiva) {
                return response()->json(['message' => 'No hay sesión activa'], 404);
            }

            $resumen = $this->cajaService->getResumenCierre($sesionActiva->id);

            return response()->json([
                'status' => true,
                'data' => $resumen
            ]);
        } catch (Exception $e) {
            return response()->json(['message' => $e->getMessage()], 400);
        }
    }

    /**
     * Cerrar caja
     */
    public function cerrar(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'monto_final_fisico' => 'required|numeric|min:0',
            'desglose' => 'nullable|array',
            'comentario' => 'nullable|string'
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        try {
            $sesionActiva = $this->cajaService->getSesionActiva(auth()->id());

            if (!$sesionActiva) {
                return response()->json(['message' => 'No tienes una sesión de caja abierta'], 404);
            }

            $sesion = $this->cajaService->cerrarCaja(
                $sesionActiva->id,
                $request->monto_final_fisico,
                $request->desglose ?? [],
                $request->comentario
            );

            return response()->json([
                'message' => 'Caja cerrada correctamente',
                'data' => $sesion
            ]);
        } catch (Exception $e) {
            return response()->json(['message' => $e->getMessage()], 400);
        }
    }
    /**
     * Obtener historial de sesiones de caja
     */
    public function historial(Request $request)
    {
        try {
            $filters = $request->only(['fecha_desde', 'fecha_hasta', 'user_id', 'estado', 'caja_id', 'per_page']);

            // Si no es admin, forzar el filtro por su propio user_id
            if (!$request->user()->hasRole('admin')) {
                $filters['user_id'] = $request->user()->id;
            }

            $historial = $this->cajaService->getHistorial($filters);

            return response()->json([
                'status' => true,
                'data' => $historial
            ]);
        } catch (Exception $e) {
            return response()->json(['message' => $e->getMessage()], 400);
        }
    }
}

