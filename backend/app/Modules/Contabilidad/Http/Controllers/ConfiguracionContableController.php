<?php

declare(strict_types=1);

namespace App\Modules\Contabilidad\Http\Controllers;

use App\Http\Controllers\Controller;
use App\Modules\Contabilidad\Http\Requests\BulkUpdateConfiguracionContableRequest;
use App\Modules\Contabilidad\Http\Requests\UpdateConfiguracionContableRequest;
use App\Modules\Contabilidad\Services\ConfiguracionContableService;
use App\Modules\Shared\Traits\ApiResponseTrait;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Throwable;

class ConfiguracionContableController extends Controller
{
    use ApiResponseTrait;

    public function __construct(
        private readonly ConfiguracionContableService $configService
    ) {}

    /**
     * Listar las configuraciones contables automáticas.
     */
    public function index(Request $request): JsonResponse
    {
        try {
            $grupo = $request->query('grupo');
            $configuraciones = $this->configService->obtenerConfiguraciones($grupo);

            return response()->json([
                'status' => 200,
                'success' => true,
                'data' => $configuraciones,
            ]);
        } catch (Throwable $e) {
            return response()->json([
                'status' => 500,
                'success' => false,
                'message' => 'Error al obtener la configuración contable: ' . $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Actualizar una configuración contable individual.
     */
    public function update(UpdateConfiguracionContableRequest $request, int $id): JsonResponse
    {
        try {
            $cuentaId = $request->input('cuenta_id');
            $config = $this->configService->actualizar($id, $cuentaId !== null ? (int) $cuentaId : null);

            return response()->json([
                'status' => 200,
                'success' => true,
                'message' => 'Configuración contable actualizada correctamente',
                'data' => $config,
            ]);
        } catch (Throwable $e) {
            return response()->json([
                'status' => 422,
                'success' => false,
                'message' => $e->getMessage(),
            ], 422);
        }
    }

    /**
     * Actualizar múltiples configuraciones contables en lote.
     */
    public function bulkUpdate(BulkUpdateConfiguracionContableRequest $request): JsonResponse
    {
        try {
            $configs = $request->validated()['configs'];
            $updated = $this->configService->actualizarBulk($configs);

            return response()->json([
                'status' => 200,
                'success' => true,
                'message' => 'Configuraciones contables actualizadas correctamente',
                'data' => $updated,
            ]);
        } catch (Throwable $e) {
            return response()->json([
                'status' => 422,
                'success' => false,
                'message' => $e->getMessage(),
            ], 422);
        }
    }
}
