<?php

namespace App\Modules\Ecf\Http\Controllers;

use App\Http\Controllers\Controller;
use App\Modules\Ecf\Services\DgiiMockService;
use Illuminate\Http\Request;

/**
 * Endpoints HTTP del Simulador Local (Mock Server) de la API e-CF DGII.
 */
class DgiiMockController extends Controller
{
    public function __construct(
        private readonly DgiiMockService $mockService
    ) {}

    /**
     * GET /api/v2/dgii-mock/autenticacion/api/semilla
     */
    public function semilla()
    {
        $xml = $this->mockService->generarSemillaXml();
        return response($xml, 200, ['Content-Type' => 'application/xml; charset=UTF-8']);
    }

    /**
     * POST /api/v2/dgii-mock/autenticacion/api/validacion
     * POST /api/v2/dgii-mock/autenticacion/api/Autenticacion/ValidarSemilla
     */
    public function validarSemilla(Request $request)
    {
        try {
            $xml = $this->extractUploadedOrRawXml($request);
            $tokenData = $this->mockService->validarSemillaFirmada($xml);
            return response()->json($tokenData, 200);
        } catch (\Throwable $e) {
            return response()->json([
                'error'   => 'ValidacionSemillaFallida',
                'mensaje' => $e->getMessage(),
            ], 400);
        }
    }

    /**
     * POST /api/v2/dgii-mock/recepcion/api/ecf
     * POST /api/v2/dgii-mock/recepcion/api/FacturasElectronicas
     */
    public function recepcionEcf(Request $request)
    {
        try {
            $xml = $this->extractUploadedOrRawXml($request);
            $authHeader = $request->header('Authorization');
            $result = $this->mockService->recibirEcf($xml, $authHeader);

            $status = ($result['estado'] ?? '') === 'Rechazado' ? 422 : 200;
            return response()->json($result, $status);
        } catch (\Throwable $e) {
            return response()->json([
                'estado'  => 'Rechazado',
                'error'   => [$e->getMessage()],
                'mensaje' => $e->getMessage(),
            ], 401);
        }
    }

    /**
     * POST /api/v2/dgii-mock/recepcionfc/api/recepcion
     */
    public function recepcionRfce(Request $request)
    {
        try {
            $xml = $this->extractUploadedOrRawXml($request);
            $authHeader = $request->header('Authorization');
            $result = $this->mockService->recibirRfce($xml, $authHeader);

            $status = ($result['estado'] ?? '') === 'Rechazado' ? 422 : 200;
            return response()->json($result, $status);
        } catch (\Throwable $e) {
            return response()->json([
                'estado'   => 'Rechazado',
                'mensajes' => [['codigo' => 'AUTH-001', 'valor' => $e->getMessage()]],
            ], 401);
        }
    }

    /**
     * GET /api/v2/dgii-mock/consultaresultado/api/consultas/estado?trackId=...
     */
    public function consultarEstado(Request $request)
    {
        try {
            $trackId = (string) ($request->query('trackId') ?? $request->query('trackid') ?? '');
            $authHeader = $request->header('Authorization');
            $result = $this->mockService->consultarTrackId($trackId, $authHeader);
            return response()->json($result, 200);
        } catch (\Throwable $e) {
            return response()->json([
                'error'   => 'ConsultaFallida',
                'mensaje' => $e->getMessage(),
            ], 401);
        }
    }

    private function extractUploadedOrRawXml(Request $request): string
    {
        if ($request->hasFile('xml')) {
            return (string) file_get_contents($request->file('xml')->getRealPath());
        }

        $raw = trim((string) $request->getContent());
        if ($raw !== '') {
            return $raw;
        }

        return (string) $request->input('xml', '');
    }
}

