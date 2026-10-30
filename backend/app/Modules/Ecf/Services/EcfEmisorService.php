<?php

namespace App\Modules\Ecf\Services;

use App\Models\Factura;
use App\Models\NotaCredito;
use App\Modules\Ecf\Models\EcfConfiguracion;
use App\Modules\Ecf\Models\EcfDocumento;
use Illuminate\Support\Facades\Log;
use RuntimeException;

class EcfEmisorService
{
    public function __construct(
        private readonly EcfCertificateService $certificateService,
        private readonly EcfXmlBuilder $xmlBuilder,
        private readonly EcfXsdValidator $xsdValidator,
        private readonly XmlDsigSigner $signer,
        private readonly QrTimbreBuilder $qrBuilder,
        private readonly DgiiApiClient $apiClient
    ) {}

    /**
     * Genera, valida contra XSD, firma digitalmente con .p12 (SHA-256), calcula el QR oficial
     * y transmite a la DGII (o al Mock Server local) el e-CF de una Factura.
     */
    public function emitirFactura(Factura $factura, bool $transmitir = true): ?EcfDocumento
    {
        $ncf = strtoupper(trim((string) $factura->ncf));
        if (!str_starts_with($ncf, 'E')) {
            return null; // Solo comprobantes electrónicos (Serie E)
        }

        $config = EcfConfiguracion::obtenerActiva();
        $this->certificateService->ensureCertificateReady($config);

        $fechaHoraFirma = now()->format('d-m-Y H:i:s');

        // 1. Construir XML <ECF>
        $build = $this->xmlBuilder->buildFromFactura($factura, $config, $fechaHoraFirma);

        // 2. Firmar digitalmente con clave privada del .p12 (XMLDSIG SHA-256)
        $firmaEcf = $this->signer->signXml(
            $build['xml'],
            $config->getEffectiveCertPath(),
            $config->getPasswordPlain()
        );

        $xmlFirmado = $firmaEcf['xml_firmado'];
        $codigoSeguridad = $firmaEcf['codigo_seguridad'];

        // 3. Validar XML firmado contra esquema XSD
        $validacionXsd = $this->xsdValidator->validate($xmlFirmado, $build['tipo_ecf']);

        // 4. Si es E32 < RD$250,000, construir y firmar también el <RFCE> (Resumen Factura Consumo)
        $xmlRfceFirmado = null;
        if ($build['es_resumen_fc']) {
            $rfceUnsigned = $this->xmlBuilder->buildRfceXml($build, $config, $codigoSeguridad);
            $firmaRfce = $this->signer->signXml(
                $rfceUnsigned,
                $config->getEffectiveCertPath(),
                $config->getPasswordPlain()
            );
            $xmlRfceFirmado = $firmaRfce['xml_firmado'];
        }

        // 5. Construir URL oficial del Código QR (ConsultaTimbre o ConsultaTimbreFC)
        $qrUrl = $this->qrBuilder->buildQrUrl(
            $config->ambiente ?: 'mock',
            $build['tipo_ecf'],
            $build['rnc_emisor'],
            $build['rnc_comprador'],
            $build['encf'],
            $build['fecha_emision_dgii'],
            (float) $build['monto_total'],
            $fechaHoraFirma,
            $codigoSeguridad
        );

        // 6. Guardar XML firmado en disco para respaldo fiscal (5-10 años exigidos por DGII)
        $xmlPath = $this->persistXmlFile($build['encf'], $xmlFirmado);

        // 7. Crear o actualizar registro en ecf_documentos
        $ecfDoc = EcfDocumento::updateOrCreate(
            ['encf' => $build['encf']],
            [
                'factura_id'             => $factura->id,
                'tipo_ecf'               => $build['tipo_ecf'],
                'es_resumen_fc'          => $build['es_resumen_fc'],
                'rnc_emisor'             => $build['rnc_emisor'],
                'rnc_comprador'          => $build['rnc_comprador'],
                'razon_social_comprador' => $build['razon_social_comprador'],
                'monto_gravado'          => $build['monto_gravado'],
                'monto_exento'           => $build['monto_exento'],
                'total_itbis'            => $build['total_itbis'],
                'monto_total'            => $build['monto_total'],
                'codigo_seguridad'       => $codigoSeguridad,
                'fecha_emision'          => $build['fecha_emision_sql'],
                'fecha_hora_firma'       => $fechaHoraFirma,
                'qr_url'                 => $qrUrl,
                'xml_path'               => $xmlPath,
                'xml_firmado'            => $xmlFirmado,
                'xml_rfce_firmado'       => $xmlRfceFirmado,
                'xsd_valido'             => $validacionXsd['valid'],
                'xsd_errores'            => $validacionXsd['errors'] ?: null,
                'ambiente'               => $config->ambiente ?: 'mock',
                'estado_dgii'            => $validacionXsd['valid'] ? 'PENDIENTE' : 'ERROR_XSD',
            ]
        );

        // 8. Transmitir a la DGII (o Mock Server) si está activo
        if ($transmitir && $config->envio_automatico && $validacionXsd['valid']) {
            $ecfDoc = $this->transmitirDocumento($ecfDoc, $config);
        }

        return $ecfDoc;
    }

    /**
     * Genera, firma y transmite una Nota de Crédito Electrónica (E34).
     */
    public function emitirNotaCredito(NotaCredito $nota, bool $transmitir = true): ?EcfDocumento
    {
        $ncf = strtoupper(trim((string) $nota->ncf));
        if (!str_starts_with($ncf, 'E')) {
            return null;
        }

        $config = EcfConfiguracion::obtenerActiva();
        $this->certificateService->ensureCertificateReady($config);

        $fechaHoraFirma = now()->format('d-m-Y H:i:s');
        $build = $this->xmlBuilder->buildFromNotaCredito($nota, $config, $fechaHoraFirma);

        $firmaEcf = $this->signer->signXml(
            $build['xml'],
            $config->getEffectiveCertPath(),
            $config->getPasswordPlain()
        );

        $xmlFirmado = $firmaEcf['xml_firmado'];
        $codigoSeguridad = $firmaEcf['codigo_seguridad'];
        $validacionXsd = $this->xsdValidator->validate($xmlFirmado, $build['tipo_ecf']);

        $qrUrl = $this->qrBuilder->buildQrUrl(
            $config->ambiente ?: 'mock',
            $build['tipo_ecf'],
            $build['rnc_emisor'],
            $build['rnc_comprador'],
            $build['encf'],
            $build['fecha_emision_dgii'],
            (float) $build['monto_total'],
            $fechaHoraFirma,
            $codigoSeguridad
        );

        $xmlPath = $this->persistXmlFile($build['encf'], $xmlFirmado);

        $ecfDoc = EcfDocumento::updateOrCreate(
            ['encf' => $build['encf']],
            [
                'factura_id'             => $nota->factura_id,
                'nota_credito_id'        => $nota->id,
                'tipo_ecf'               => $build['tipo_ecf'],
                'es_resumen_fc'          => false,
                'rnc_emisor'             => $build['rnc_emisor'],
                'rnc_comprador'          => $build['rnc_comprador'],
                'razon_social_comprador' => $build['razon_social_comprador'],
                'monto_gravado'          => $build['monto_gravado'],
                'monto_exento'           => $build['monto_exento'],
                'total_itbis'            => $build['total_itbis'],
                'monto_total'            => $build['monto_total'],
                'codigo_seguridad'       => $codigoSeguridad,
                'fecha_emision'          => $build['fecha_emision_sql'],
                'fecha_hora_firma'       => $fechaHoraFirma,
                'qr_url'                 => $qrUrl,
                'xml_path'               => $xmlPath,
                'xml_firmado'            => $xmlFirmado,
                'xsd_valido'             => $validacionXsd['valid'],
                'xsd_errores'            => $validacionXsd['errors'] ?: null,
                'ambiente'               => $config->ambiente ?: 'mock',
                'estado_dgii'            => $validacionXsd['valid'] ? 'PENDIENTE' : 'ERROR_XSD',
            ]
        );

        if ($transmitir && $config->envio_automatico && $validacionXsd['valid']) {
            $ecfDoc = $this->transmitirDocumento($ecfDoc, $config);
        }

        return $ecfDoc;
    }

    /**
     * Transmite (o retransmite) un EcfDocumento ya firmado hacia la DGII / Mock Server.
     */
    public function transmitirDocumento(EcfDocumento $ecfDoc, ?EcfConfiguracion $config = null): EcfDocumento
    {
        $config = $config ?: EcfConfiguracion::obtenerActiva();

        try {
            if ($ecfDoc->es_resumen_fc && !empty($ecfDoc->xml_rfce_firmado)) {
                $resp = $this->apiClient->enviarRfce($ecfDoc->xml_rfce_firmado, $ecfDoc->encf, $config);
            } else {
                $resp = $this->apiClient->enviarEcf($ecfDoc->xml_firmado, $ecfDoc->encf, $config);
            }

            $estadoNormalizado = $this->normalizarEstadoDgii($resp['estado'] ?? null, !empty($resp['trackId']));

            $ecfDoc->update([
                'ambiente'       => $config->ambiente ?: 'mock',
                'track_id'       => $resp['trackId'] ?? $ecfDoc->track_id,
                'estado_dgii'    => $estadoNormalizado,
                'respuesta_dgii' => $resp,
                'fecha_envio'    => now(),
                'intentos_envio' => $ecfDoc->intentos_envio + 1,
                'ultimo_error'   => ($estadoNormalizado === 'RECHAZADO')
                    ? json_encode($resp['error'] ?? ($resp['mensajes'] ?? []), JSON_UNESCAPED_UNICODE)
                    : null,
            ]);
        } catch (\Throwable $e) {
            Log::warning("Fallo al transmitir e-CF {$ecfDoc->encf} a DGII: " . $e->getMessage());
            $ecfDoc->update([
                'estado_dgii'    => 'ERROR_ENVIO',
                'intentos_envio' => $ecfDoc->intentos_envio + 1,
                'ultimo_error'   => $e->getMessage(),
            ]);
        }

        return $ecfDoc->fresh();
    }

    /**
     * Consulta en la DGII / Mock el estado actual de un documento por su TrackId.
     */
    public function actualizarEstadoPorTrackId(EcfDocumento $ecfDoc): EcfDocumento
    {
        if (empty($ecfDoc->track_id)) {
            throw new RuntimeException('Este comprobante aún no posee un TrackId asignado.');
        }

        $config = EcfConfiguracion::obtenerActiva();
        $resp = $this->apiClient->consultarEstadoTrackId($ecfDoc->track_id, $config);
        $estadoNormalizado = $this->normalizarEstadoDgii($resp['estado'] ?? null, true);

        $ecfDoc->update([
            'estado_dgii'    => $estadoNormalizado,
            'respuesta_dgii' => $resp,
        ]);

        return $ecfDoc->fresh();
    }

    private function normalizarEstadoDgii(?string $estadoRaw, bool $tieneTrackId): string
    {
        $clean = strtoupper(trim((string) $estadoRaw));

        return match (true) {
            str_contains($clean, 'CONDICIONAL') => 'ACEPTADO_CONDICIONAL',
            str_contains($clean, 'ACEPTADO')    => 'ACEPTADO',
            str_contains($clean, 'RECHAZADO')   => 'RECHAZADO',
            str_contains($clean, 'PROCESO')     => 'EN_PROCESO',
            $tieneTrackId                       => 'EN_PROCESO',
            default                             => 'PENDIENTE',
        };
    }

    private function persistXmlFile(string $encf, string $xmlContent): string
    {
        $subDir = 'dgii/xml/' . now()->format('Y/m');
        $fullDir = storage_path("app/{$subDir}");

        if (!is_dir($fullDir)) {
            @mkdir($fullDir, 0755, true);
        }

        $fullPath = "{$fullDir}/{$encf}.xml";
        @file_put_contents($fullPath, $xmlContent);

        return "{$subDir}/{$encf}.xml";
    }
}

