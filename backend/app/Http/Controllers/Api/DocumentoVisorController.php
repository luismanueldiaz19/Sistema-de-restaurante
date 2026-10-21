<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Services\DocumentoSeguroService;
use App\Models\NotaCredito;
use Barryvdh\DomPDF\Facade\Pdf;
use Illuminate\Http\Request;

class DocumentoVisorController extends Controller
{
    /**
     * Visualiza un documento mediante un token temporal encriptado.
     * Ruta pública: /api/documentos/ver/{token}
     */
    public function ver(Request $request, string $token)
    {
        try {
            $datos = DocumentoSeguroService::validarYObtenerDatos($token);
            $tipo = $datos['tipo'];
            $id = $datos['id'];

            switch ($tipo) {
                case 'nota_credito':
                    $notaCredito = NotaCredito::with(['detalles.producto', 'factura.cliente', 'factura.user'])->findOrFail($id);
                    $pdf = Pdf::loadView('pdf.nota_credito', compact('notaCredito'));
                    return $pdf->stream('nota_credito_' . $notaCredito->id . '.pdf');

                default:
                    abort(404, 'Tipo de documento no soportado.');
            }
        } catch (\Exception $e) {
            return response(
                "<div style='font-family:-apple-system,BlinkMacSystemFont,Segoe UI,Roboto,sans-serif;text-align:center;padding:60px 20px;'>" .
                "<div style='font-size:48px;margin-bottom:16px;'>🔒</div>" .
                "<h2 style='color:#e74c3c;margin-bottom:8px;'>Enlace Expirado o No Válido</h2>" .
                "<p style='color:#7f8c8d;font-size:14px;max-width:400px;margin:0 auto 20px auto;'>" . htmlspecialchars($e->getMessage(), ENT_QUOTES, 'UTF-8') . "</p>" .
                "<p style='font-size:12px;color:#bdc3c7;'>Por favor genera un nuevo enlace desde el sistema.</p>" .
                "</div>",
                403,
                ['Content-Type' => 'text/html']
            );
        }
    }

    /**
     * Endpoint autenticado para obtener la URL temporal encriptada de un documento.
     * GET /api/documentos/{tipo}/{id}/url-temporal
     */
    public function generarUrl(string $tipo, int $id)
    {
        $url = DocumentoSeguroService::generarUrlTemporal($tipo, $id, 15);

        return response()->json([
            'success' => true,
            'url'     => $url,
            'expira_en_minutos' => 15,
        ]);
    }
}
