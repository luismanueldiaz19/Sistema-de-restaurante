<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\ConfiguracionContable;
use App\Models\CatalogoCuenta;
use Illuminate\Support\Facades\Validator;

class ConfiguracionContableController extends Controller
{
    /**
     * Display a listing of accounting configurations.
     *
     * @return \Illuminate\Http\JsonResponse
     */
    public function index()
    {
        try {
            $configuraciones = ConfiguracionContable::with('cuenta')->get();

            return response()->json([
                'status' => 200,
                'data' => $configuraciones
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'status' => 500,
                'message' => 'Error al obtener la configuración contable',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Update a specific configuration.
     *
     * @param  \Illuminate\Http\Request  $request
     * @param  int  $id
     * @return \Illuminate\Http\JsonResponse
     */
    public function update(Request $request, $id)
    {
        try {
            $config = ConfiguracionContable::find($id);

            if (!$config) {
                return response()->json([
                    'status' => 404,
                    'message' => 'Configuración no encontrada'
                ], 404);
            }

            $validator = Validator::make($request->all(), [
                'cuenta_id' => 'nullable|exists:catalogo_cuentas,id',
            ]);

            if ($validator->fails()) {
                return response()->json([
                    'status' => 422,
                    'message' => 'Datos inválidos',
                    'errors' => $validator->errors()
                ], 422);
            }

            $cuentaId = $request->input('cuenta_id');

            if ($cuentaId) {
                $cuenta = CatalogoCuenta::find($cuentaId);
                if (!$cuenta->permite_movimiento) {
                    return response()->json([
                        'status' => 422,
                        'message' => 'La cuenta seleccionada debe ser una cuenta de detalle que permita movimientos.'
                    ], 422);
                }
            }

            $config->cuenta_id = $cuentaId;
            $config->save();

            return response()->json([
                'status' => 200,
                'message' => 'Configuración contable actualizada correctamente',
                'data' => $config->load('cuenta')
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'status' => 500,
                'message' => 'Error al actualizar la configuración contable',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Bulk update multiple configurations.
     *
     * @param  \Illuminate\Http\Request  $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function bulkUpdate(Request $request)
    {
        try {
            $configs = $request->input('configs');

            if (!is_array($configs)) {
                return response()->json([
                    'status' => 422,
                    'message' => 'Se requiere una lista de configuraciones'
                ], 422);
            }

            foreach ($configs as $item) {
                if (!isset($item['id'])) {
                    continue;
                }

                $config = ConfiguracionContable::find($item['id']);
                if (!$config) {
                    continue;
                }

                $cuentaId = $item['cuenta_id'] ?? null;

                if ($cuentaId) {
                    $cuenta = CatalogoCuenta::find($cuentaId);
                    if ($cuenta && $cuenta->permite_movimiento) {
                        $config->cuenta_id = $cuentaId;
                        $config->save();
                    }
                } else {
                    $config->cuenta_id = null;
                    $config->save();
                }
            }

            $updatedConfigs = ConfiguracionContable::with('cuenta')->get();

            return response()->json([
                'status' => 200,
                'message' => 'Configuraciones contables actualizadas correctamente',
                'data' => $updatedConfigs
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'status' => 500,
                'message' => 'Error al actualizar configuraciones en bloque',
                'error' => $e->getMessage()
            ], 500);
        }
    }
}
