<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Services\CajaService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;
use Exception;

class CajaController extends Controller
{
    protected $cajaService;

    public function __construct(CajaService $cajaService)
    {
        $this->cajaService = $cajaService;
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

            return response()->json([
                'message' => 'Caja abierta correctamente',
                'data' => $sesion
            ], 201);
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
}
