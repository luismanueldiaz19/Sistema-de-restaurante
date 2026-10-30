<?php

namespace App\Modules\Ecf\Services;

use DOMDocument;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Str;
use RuntimeException;

/**
 * Simulador Local Oficial de la API de Facturación Electrónica (e-CF) de la DGII.
 * Ejecuta las mismas validaciones criptográficas (XMLDSIG SHA-256) y de esquema (XSD)
 * que el Sandbox oficial de la DGII, permitiendo trabajar 100% en local.
 */
class DgiiMockService
{
    public function __construct(
        private readonly XmlDsigSigner $signer,
        private readonly EcfXsdValidator $xsdValidator
    ) {}

    /**
     * Paso 1 DGII: GET /autenticacion/api/semilla
     */
    public function generarSemillaXml(): string
    {
        $nonce = base64_encode(random_bytes(24));
        $fecha = now()->toIso8601String();

        Cache::put("dgii_mock_semilla:{$nonce}", true, now()->addMinutes(10));

        $dom = new DOMDocument('1.0', 'UTF-8');
        $root = $dom->createElement('SemillaModel');
        $dom->appendChild($root);

        $valorEl = $dom->createElement('valor', $nonce);
        $fechaEl = $dom->createElement('fecha', $fecha);
        $root->appendChild($valorEl);
        $root->appendChild($fechaEl);

        return (string) $dom->saveXML();
    }

    /**
     * Paso 2 DGII: POST /autenticacion/api/validacioncertificado (o /validacion)
     */
    public function validarSemillaFirmada(string $signedSemillaXml): array
    {
        $xsdCheck = $this->xsdValidator->validate($signedSemillaXml);
        if (!$xsdCheck['valid']) {
            throw new RuntimeException('Semilla rechazada por esquema XSD: ' . implode('; ', $xsdCheck['errors']));
        }

        $sigCheck = $this->signer->verifyXml($signedSemillaXml);
        if (!$sigCheck['valid']) {
            throw new RuntimeException('Firma digital de la semilla inválida: ' . ($sigCheck['error'] ?? 'Error desconocido'));
        }

        $dom = new DOMDocument();
        @$dom->loadXML($signedSemillaXml);
        $valorNode = $dom->getElementsByTagName('valor')->item(0);
        $valor = $valorNode ? trim($valorNode->textContent) : '';

        if ($valor === '') {
            throw new RuntimeException('La semilla firmada no contiene etiqueta <valor>.');
        }

        $token = 'dgii_mock_tok_' . Str::random(40);
        $expido = now();
        $expira = now()->addHour();

        Cache::put("dgii_mock_token:{$token}", [
            'cn'     => $sigCheck['subject_cn'] ?? 'PruebaFacturacionDGII',
            'expira' => $expira->toIso8601String(),
        ], $expira);

        return [
            'token'  => $token,
            'expido' => $expido->format('Y-m-d\TH:i:s\Z'),
            'expira' => $expira->format('Y-m-d\TH:i:s\Z'),
        ];
    }

    /**
     * Paso 3A DGII: POST /recepcion/api/facturaselectronicas (o /recepcion/api/ecf)
     */
    public function recibirEcf(string $signedEcfXml, ?string $bearerToken): array
    {
        $this->assertValidBearerToken($bearerToken);

        $sigCheck = $this->signer->verifyXml($signedEcfXml);
        if (!$sigCheck['valid']) {
            return [
                'trackId' => null,
                'codigo'  => '2',
                'estado'  => 'Rechazado',
                'error'   => [$sigCheck['error'] ?? 'Firma digital XMLDSIG inválida.'],
                'mensajes' => [
                    ['codigo' => 'SIGN-001', 'valor' => $sigCheck['error'] ?? 'Firma digital inválida'],
                ],
            ];
        }

        $dom = new DOMDocument();
        @$dom->loadXML($signedEcfXml);
        $encf = trim($dom->getElementsByTagName('eNCF')->item(0)?->textContent ?? '');
        $tipoEcf = trim($dom->getElementsByTagName('TipoeCF')->item(0)?->textContent ?? '');
        $rncEmisor = trim($dom->getElementsByTagName('RNCEmisor')->item(0)?->textContent ?? '');

        $xsdCheck = $this->xsdValidator->validate($signedEcfXml, $tipoEcf);
        if (!$xsdCheck['valid']) {
            return [
                'trackId'  => (string) Str::uuid(),
                'codigo'   => '2',
                'estado'   => 'Rechazado',
                'rnc'      => $rncEmisor,
                'encf'     => $encf,
                'error'    => $xsdCheck['errors'],
                'mensajes' => array_map(
                    fn ($msg) => ['codigo' => 'XSD-001', 'valor' => $msg],
                    $xsdCheck['errors']
                ),
            ];
        }

        $trackId = (string) Str::uuid();
        $resultPayload = [
            'trackId'            => $trackId,
            'codigo'             => '1',
            'estado'             => 'Aceptado',
            'rnc'                => $rncEmisor,
            'encf'               => $encf,
            'secuenciaUtilizada' => true,
            'fechaRecepcion'     => now()->format('d/m/Y H:i:s'),
            'codigoSeguridad'    => $sigCheck['codigo_seguridad'],
            'error'              => [],
            'mensajes'           => [
                [
                    'codigo' => '0',
                    'valor'  => 'Comprobante aceptado satisfactoriamente (Simulador Local DGII - Firma SHA-256 y Esquema XSD verificados).',
                ],
            ],
        ];

        Cache::put("dgii_mock_track:{$trackId}", $resultPayload, now()->addDays(7));

        return $resultPayload;
    }

    /**
     * Paso 3B DGII: POST /recepcionfc/api/recepcion (Resumen Factura Consumo E32 < RD$250,000)
     */
    public function recibirRfce(string $signedRfceXml, ?string $bearerToken): array
    {
        $this->assertValidBearerToken($bearerToken);

        $sigCheck = $this->signer->verifyXml($signedRfceXml);
        if (!$sigCheck['valid']) {
            return [
                'codigo'             => '2',
                'estado'             => 'Rechazado',
                'secuenciaUtilizada' => false,
                'mensajes'           => [
                    ['codigo' => 'SIGN-RFCE', 'valor' => $sigCheck['error'] ?? 'Firma RFCE inválida'],
                ],
            ];
        }

        $xsdCheck = $this->xsdValidator->validate($signedRfceXml, '32');
        $dom = new DOMDocument();
        @$dom->loadXML($signedRfceXml);
        $encf = trim($dom->getElementsByTagName('eNCF')->item(0)?->textContent ?? '');
        $rncEmisor = trim($dom->getElementsByTagName('RNCEmisor')->item(0)?->textContent ?? '');

        if (!$xsdCheck['valid']) {
            return [
                'rnc'                => $rncEmisor,
                'encf'               => $encf,
                'codigo'             => '2',
                'estado'             => 'Rechazado',
                'secuenciaUtilizada' => false,
                'mensajes'           => array_map(
                    fn ($msg) => ['codigo' => 'XSD-RFCE', 'valor' => $msg],
                    $xsdCheck['errors']
                ),
            ];
        }

        $trackId = 'RFCE-' . Str::upper(Str::random(12));
        $result = [
            'trackId'            => $trackId,
            'rnc'                => $rncEmisor,
            'encf'               => $encf,
            'secuenciaUtilizada' => true,
            'codigo'             => '1',
            'estado'             => 'Aceptado',
            'mensajes'           => [
                [
                    'codigo' => '0',
                    'valor'  => 'Resumen Factura de Consumo (< RD$250,000) aceptado en Simulador Local DGII.',
                ],
            ],
        ];

        Cache::put("dgii_mock_track:{$trackId}", $result, now()->addDays(7));

        return $result;
    }

    /**
     * Paso 4 DGII: GET /consultaresultado/api/consultas/estado?trackid=...
     */
    public function consultarTrackId(string $trackId, ?string $bearerToken = null): array
    {
        if ($bearerToken !== null) {
            $this->assertValidBearerToken($bearerToken);
        }

        $cached = Cache::get("dgii_mock_track:{$trackId}");
        if ($cached) {
            return $cached;
        }

        return [
            'trackId'            => $trackId,
            'codigo'             => '1',
            'estado'             => 'Aceptado',
            'secuenciaUtilizada' => true,
            'fechaRecepcion'     => now()->format('d/m/Y H:i:s'),
            'mensajes'           => [
                ['codigo' => '0', 'valor' => 'TrackId consultado en Simulador Local DGII.'],
            ],
        ];
    }

    private function assertValidBearerToken(?string $bearerToken): void
    {
        $clean = trim(preg_replace('/^Bearer\s+/i', '', (string) $bearerToken));
        if ($clean === '' || !Cache::has("dgii_mock_token:{$clean}")) {
            throw new RuntimeException('No autorizado en DGII Mock: Token Bearer inválido o expirado.');
        }
    }
}

