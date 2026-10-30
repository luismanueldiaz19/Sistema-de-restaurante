<?php

namespace App\Modules\Ecf\Http\Controllers;

use App\Http\Controllers\Controller;
use App\Models\Factura;
use App\Modules\Ecf\Models\EcfConfiguracion;
use App\Modules\Ecf\Models\EcfDocumento;
use App\Modules\Ecf\Services\DgiiApiClient;
use App\Modules\Ecf\Services\EcfCertificateService;
use App\Modules\Ecf\Services\EcfEmisorService;
use App\Modules\Ecf\Services\XmlDsigSigner;
use Illuminate\Http\Request;

class EcfController extends Controller
{
    public function __construct(
        private readonly EcfCertificateService $certService,
        private readonly DgiiApiClient $apiClient,
        private readonly EcfEmisorService $emisorService,
        private readonly XmlDsigSigner $signer
    ) {}

    /**
     * GET /api/v2/ecf/estado-sistema
     * Resumen completo del módulo e-CF: configuración emisor, estado del certificado .p12 y KPIs de envíos.
     */
    public function estadoSistema()
    {
        $config = EcfConfiguracion::obtenerActiva();

        // Auto-provisionar certificado de prueba si está en modo mock y aún no existe
        if ($config->ambiente === 'mock' && !is_file($config->getEffectiveCertPath())) {
            try {
                $this->certService->ensureCertificateReady($config);
            } catch (\Throwable $e) {
                // Se reporta en inspectCertificate abajo
            }
        }

        $certMeta = $this->certService->inspectCertificate(
            $config->getEffectiveCertPath(),
            $config->getPasswordPlain()
        );

        $stats = [
            'total'      => EcfDocumento::count(),
            'aceptados'  => EcfDocumento::whereIn('estado_dgii', ['ACEPTADO', 'ACEPTADO_CONDICIONAL'])->count(),
            'en_proceso' => EcfDocumento::where('estado_dgii', 'EN_PROCESO')->count(),
            'pendientes' => EcfDocumento::where('estado_dgii', 'PENDIENTE')->count(),
            'rechazados' => EcfDocumento::whereIn('estado_dgii', ['RECHAZADO', 'ERROR_ENVIO', 'ERROR_XSD'])->count(),
        ];

        return response()->json([
            'status'        => true,
            'configuracion' => $config,
            'certificado'   => $certMeta,
            'estadisticas'  => $stats,
        ]);
    }

    /**
     * PUT /api/v2/ecf/configuracion
     */
    public function actualizarConfiguracion(Request $request)
    {
        $validated = $request->validate([
            'ambiente'             => 'required|in:mock,TesteCF,CerteCF,eCF',
            'rnc_emisor'           => 'required|string|min:9|max:15',
            'razon_social'         => 'required|string|max:150',
            'nombre_comercial'     => 'nullable|string|max:150',
            'direccion'            => 'required|string|max:250',
            'municipio'            => 'nullable|string|max:10',
            'provincia'            => 'nullable|string|max:10',
            'telefono'             => 'nullable|string|max:25',
            'correo'               => 'nullable|email|max:120',
            'sitio_web'            => 'nullable|string|max:150',
            'certificado_password' => 'nullable|string|max:120',
            'envio_automatico'     => 'nullable|boolean',
        ]);

        $config = EcfConfiguracion::obtenerActiva();
        $config->fill([
            'ambiente'         => $validated['ambiente'],
            'rnc_emisor'       => preg_replace('/[^0-9]/', '', $validated['rnc_emisor']),
            'razon_social'     => $validated['razon_social'],
            'nombre_comercial' => $validated['nombre_comercial'] ?? null,
            'direccion'        => $validated['direccion'],
            'municipio'        => $validated['municipio'] ?? null,
            'provincia'        => $validated['provincia'] ?? null,
            'telefono'         => $validated['telefono'] ?? null,
            'correo'           => $validated['correo'] ?? null,
            'sitio_web'        => $validated['sitio_web'] ?? null,
            'envio_automatico' => $validated['envio_automatico'] ?? $config->envio_automatico,
        ]);

        if (!empty($validated['certificado_password'])) {
            $config->setPasswordPlain($validated['certificado_password']);
        }

        $config->save();

        return response()->json([
            'status'        => true,
            'message'       => 'Configuración fiscal e-CF actualizada correctamente.',
            'configuracion' => $config,
        ]);
    }

    /**
     * POST /api/v2/ecf/certificado/generar-prueba
     */
    public function generarCertificadoPrueba(Request $request)
    {
        $password = (string) $request->input('password', '1234');
        $config = EcfConfiguracion::obtenerActiva();
        $outputPath = storage_path('app/dgii/certs/certificado_prueba.p12');

        try {
            $meta = $this->certService->generateTestCertificate($outputPath, $password, [
                'organizationName' => $config->razon_social ?: 'Menuxa POS',
                'commonName'       => $config->rnc_limpio ?: 'PruebaFacturacionDGII',
            ]);

            $config->certificado_path = $outputPath;
            $config->setPasswordPlain($password);
            $config->save();

            return response()->json([
                'status'      => true,
                'message'     => 'Certificado .p12 de prueba RSA-2048 generado y configurado exitosamente.',
                'certificado' => $meta,
            ]);
        } catch (\Throwable $e) {
            return response()->json([
                'status'  => false,
                'message' => 'Error generando certificado de prueba: ' . $e->getMessage(),
            ], 500);
        }
    }

    /**
     * POST /api/v2/ecf/certificado/upload
     * Permite subir el archivo .p12 / .pfx oficial de Digifirma / Viafirma / Cámara de Comercio.
     */
    public function subirCertificado(Request $request)
    {
        $request->validate([
            'certificado' => 'required|file|max:2048',
            'password'    => 'required|string',
        ]);

        try {
            $file = $request->file('certificado');
            $password = (string) $request->input('password');
            $dir = storage_path('app/dgii/certs');

            if (!is_dir($dir)) {
                @mkdir($dir, 0755, true);
            }

            $fileName = 'certificado_emisor_' . date('Ymd_His') . '.p12';
            $fullPath = "{$dir}/{$fileName}";
            $file->move($dir, $fileName);

            // Validar que la contraseña abra correctamente el .p12 antes de guardarlo en configuración
            $creds = $this->certService->loadCredentials($fullPath, $password);

            $config = EcfConfiguracion::obtenerActiva();
            $config->certificado_path = $fullPath;
            $config->setPasswordPlain($password);
            $config->save();

            return response()->json([
                'status'      => true,
                'message'     => 'Certificado digital .p12 verificado e instalado correctamente.',
                'certificado' => $creds['metadata'],
            ]);
        } catch (\Throwable $e) {
            return response()->json([
                'status'  => false,
                'message' => 'No se pudo instalar el certificado: ' . $e->getMessage(),
            ], 422);
        }
    }

    /**
     * POST /api/v2/ecf/probar-conexion
     * Prueba el ciclo completo: Certificado .p12 -> Semilla -> Firma XMLDSIG SHA-256 -> Token DGII.
     */
    public function probarConexion()
    {
        try {
            $config = EcfConfiguracion::obtenerActiva();
            $this->certService->ensureCertificateReady($config);
            $tokenResult = $this->apiClient->obtenerToken($config, true);

            return response()->json([
                'status'  => true,
                'message' => "Autenticación exitosa en ambiente [{$config->ambiente}]: Semilla firmada con SHA-256 y Token recibido.",
                'data'    => [
                    'ambiente'      => $tokenResult['ambiente'],
                    'token_preview' => substr($tokenResult['token'], 0, 22) . '...',
                    'expira'        => $tokenResult['expira'],
                    'certificado'   => $tokenResult['cert_metadata'],
                ],
            ]);
        } catch (\Throwable $e) {
            return response()->json([
                'status'  => false,
                'message' => 'Fallo en prueba de conexión e-CF: ' . $e->getMessage(),
            ], 422);
        }
    }

    /**
     * GET /api/v2/ecf/documentos
     */
    public function listarDocumentos(Request $request)
    {
        $query = EcfDocumento::query()->orderByDesc('id');

        if ($request->filled('estado')) {
            $query->where('estado_dgii', $request->query('estado'));
        }
        if ($request->filled('tipo_ecf')) {
            $query->where('tipo_ecf', $request->query('tipo_ecf'));
        }
        if ($request->filled('search')) {
            $term = trim((string) $request->query('search'));
            $query->where(function ($q) use ($term) {
                $q->where('encf', 'like', "%{$term}%")
                  ->orWhere('track_id', 'like', "%{$term}%")
                  ->orWhere('rnc_comprador', 'like', "%{$term}%")
                  ->orWhere('razon_social_comprador', 'like', "%{$term}%")
                  ->orWhere('codigo_seguridad', 'like', "%{$term}%");
            });
        }

        $docs = $query->paginate((int) $request->query('per_page', 20));

        return response()->json([
            'status' => true,
            'data'   => $docs,
        ]);
    }

    /**
     * GET /api/v2/ecf/documentos/{id}
     */
    public function verDocumento($id)
    {
        $doc = EcfDocumento::findOrFail($id);
        $verificacionFirma = $this->signer->verifyXml($doc->xml_firmado);

        return response()->json([
            'status'             => true,
            'documento'          => $doc,
            'xml_firmado'        => $doc->xml_firmado,
            'xml_rfce_firmado'   => $doc->xml_rfce_firmado,
            'verificacion_firma' => $verificacionFirma,
        ]);
    }

    /**
     * GET /api/v2/ecf/documentos/{id}/xml
     */
    public function descargarXml($id)
    {
        $doc = EcfDocumento::findOrFail($id);
        $fileName = "{$doc->rnc_emisor}{$doc->encf}.xml";

        return response($doc->xml_firmado, 200, [
            'Content-Type'        => 'application/xml; charset=UTF-8',
            'Content-Disposition' => "attachment; filename=\"{$fileName}\"",
        ]);
    }

    /**
     * POST /api/v2/ecf/documentos/{id}/reenviar
     */
    public function reenviar($id)
    {
        try {
            $doc = EcfDocumento::findOrFail($id);
            $updated = $this->emisorService->transmitirDocumento($doc);

            return response()->json([
                'status'    => true,
                'message'   => "Comprobante {$updated->encf} procesado. Estado DGII: {$updated->estado_dgii}",
                'documento' => $updated,
            ]);
        } catch (\Throwable $e) {
            return response()->json([
                'status'  => false,
                'message' => 'Error al reenviar comprobante: ' . $e->getMessage(),
            ], 422);
        }
    }

    /**
     * GET /api/v2/ecf/documentos/{id}/consultar-estado
     */
    public function consultarEstado($id)
    {
        try {
            $doc = EcfDocumento::findOrFail($id);
            $updated = $this->emisorService->actualizarEstadoPorTrackId($doc);

            return response()->json([
                'status'    => true,
                'message'   => "Estado actualizado desde DGII: {$updated->estado_dgii}",
                'documento' => $updated,
            ]);
        } catch (\Throwable $e) {
            return response()->json([
                'status'  => false,
                'message' => 'No se pudo consultar TrackId: ' . $e->getMessage(),
            ], 422);
        }
    }

    /**
     * POST /api/v2/ecf/emitir-factura/{facturaId}
     */
    public function emitirPorFactura($facturaId)
    {
        try {
            $factura = Factura::with(['cliente', 'detalles.producto'])->findOrFail($facturaId);
            $doc = $this->emisorService->emitirFactura($factura, true);

            if (!$doc) {
                return response()->json([
                    'status'  => false,
                    'message' => 'La factura no utiliza una secuencia electrónica (Serie E).',
                ], 422);
            }

            return response()->json([
                'status'    => true,
                'message'   => "e-CF {$doc->encf} generado, firmado y enviado ({$doc->estado_dgii}).",
                'documento' => $doc,
            ]);
        } catch (\Throwable $e) {
            return response()->json([
                'status'  => false,
                'message' => 'Error al emitir e-CF: ' . $e->getMessage(),
            ], 422);
        }
    }
}

