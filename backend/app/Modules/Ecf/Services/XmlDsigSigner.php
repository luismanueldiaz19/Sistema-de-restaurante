<?php

namespace App\Modules\Ecf\Services;

use DOMDocument;
use DOMElement;
use DOMXPath;
use RuntimeException;

/**
 * Motor de Firma Digital XMLDSIG (Enveloped Signature + C14N + RSA-SHA256)
 * conforme a los lineamientos técnicos de e-CF de la DGII República Dominicana.
 */
class XmlDsigSigner
{
    private const XMLDSIG_NS = 'http://www.w3.org/2000/09/xmldsig#';
    private const C14N_ALGO  = 'http://www.w3.org/TR/2001/REC-xml-c14n-20010315';
    private const SIGN_ALGO  = 'http://www.w3.org/2001/04/xmldsig-more#rsa-sha256';
    private const ENV_ALGO   = 'http://www.w3.org/2000/09/xmldsig#enveloped-signature';
    private const DIGEST_ALG = 'http://www.w3.org/2001/04/xmlenc#sha256';

    public function __construct(
        private readonly EcfCertificateService $certificateService
    ) {}

    /**
     * Firma un documento XML (<ECF>, <RFCE> o <SemillaModel>) insertando <Signature>
     * al final del nodo raíz y devuelve el XML firmado + CodigoSeguridad (6 primeros chars de SignatureValue).
     */
    public function signXml(string $unsignedXml, ?string $p12Path = null, ?string $p12Password = null): array
    {
        $creds = ($p12Path !== null && $p12Password !== null)
            ? $this->certificateService->loadCredentials($p12Path, $p12Password)
            : $this->certificateService->ensureCertificateReady();

        $dom = new DOMDocument('1.0', 'UTF-8');
        $dom->preserveWhiteSpace = false;
        $dom->formatOutput = false;

        if (!@$dom->loadXML($unsignedXml)) {
            throw new RuntimeException('El XML proporcionado para firmar no es válido.');
        }

        $root = $dom->documentElement;
        if (!$root instanceof DOMElement) {
            throw new RuntimeException('El XML no contiene un nodo raíz válido.');
        }

        // Si ya tenía un nodo Signature previo, removerlo antes de recalcular
        $existingSignatures = $root->getElementsByTagNameNS(self::XMLDSIG_NS, 'Signature');
        while ($existingSignatures->length > 0) {
            $sigNode = $existingSignatures->item(0);
            if ($sigNode && $sigNode->parentNode) {
                $sigNode->parentNode->removeChild($sigNode);
            }
        }

        // 1. Canonicalizar documento completo (C14N inclusivo sin comentarios)
        $canonicalDocument = $dom->C14N(false, false);
        if ($canonicalDocument === false || $canonicalDocument === '') {
            throw new RuntimeException('Fallo al canonicalizar (C14N) el documento XML.');
        }

        // 2. Calcular DigestValue en SHA-256 codificado en Base64
        $digestValue = base64_encode(hash('sha256', $canonicalDocument, true));

        // 3. Construir nodo <Signature xmlns="http://www.w3.org/2000/09/xmldsig#">
        $signatureEl = $dom->createElementNS(self::XMLDSIG_NS, 'Signature');
        $signedInfoEl = $dom->createElementNS(self::XMLDSIG_NS, 'SignedInfo');

        $canonMethodEl = $dom->createElementNS(self::XMLDSIG_NS, 'CanonicalizationMethod');
        $canonMethodEl->setAttribute('Algorithm', self::C14N_ALGO);
        $signedInfoEl->appendChild($canonMethodEl);

        $sigMethodEl = $dom->createElementNS(self::XMLDSIG_NS, 'SignatureMethod');
        $sigMethodEl->setAttribute('Algorithm', self::SIGN_ALGO);
        $signedInfoEl->appendChild($sigMethodEl);

        $referenceEl = $dom->createElementNS(self::XMLDSIG_NS, 'Reference');
        $referenceEl->setAttribute('URI', '');

        $transformsEl = $dom->createElementNS(self::XMLDSIG_NS, 'Transforms');
        $transformEl = $dom->createElementNS(self::XMLDSIG_NS, 'Transform');
        $transformEl->setAttribute('Algorithm', self::ENV_ALGO);
        $transformsEl->appendChild($transformEl);
        $referenceEl->appendChild($transformsEl);

        $digestMethodEl = $dom->createElementNS(self::XMLDSIG_NS, 'DigestMethod');
        $digestMethodEl->setAttribute('Algorithm', self::DIGEST_ALG);
        $referenceEl->appendChild($digestMethodEl);

        $digestValueEl = $dom->createElementNS(self::XMLDSIG_NS, 'DigestValue', $digestValue);
        $referenceEl->appendChild($digestValueEl);

        $signedInfoEl->appendChild($referenceEl);
        $signatureEl->appendChild($signedInfoEl);

        // Insertar <Signature> en el árbol antes de canonicalizar <SignedInfo> para heredar contexto XML/namespaces
        $root->appendChild($signatureEl);

        // 4. Canonicalizar <SignedInfo> y firmar con clave privada RSA-SHA256
        $canonicalSignedInfo = $signedInfoEl->C14N(false, false);
        if ($canonicalSignedInfo === false || $canonicalSignedInfo === '') {
            throw new RuntimeException('Fallo al canonicalizar el bloque <SignedInfo>.');
        }

        $rawSignature = '';
        $signedOk = openssl_sign($canonicalSignedInfo, $rawSignature, $creds['private_key'], OPENSSL_ALGO_SHA256);
        if (!$signedOk) {
            throw new RuntimeException('Fallo criptográfico en openssl_sign con RSA-SHA256.');
        }

        $signatureValue = base64_encode($rawSignature);

        // 5. Agregar <SignatureValue> y <KeyInfo><X509Data><X509Certificate>
        $sigValueEl = $dom->createElementNS(self::XMLDSIG_NS, 'SignatureValue', $signatureValue);
        $signatureEl->appendChild($sigValueEl);

        $keyInfoEl = $dom->createElementNS(self::XMLDSIG_NS, 'KeyInfo');
        $x509DataEl = $dom->createElementNS(self::XMLDSIG_NS, 'X509Data');
        $x509CertEl = $dom->createElementNS(self::XMLDSIG_NS, 'X509Certificate', $creds['cert_base64']);
        $x509DataEl->appendChild($x509CertEl);
        $keyInfoEl->appendChild($x509DataEl);
        $signatureEl->appendChild($keyInfoEl);

        // 6. Código de Seguridad oficial DGII: primeros 6 caracteres de <SignatureValue>
        $codigoSeguridad = substr($signatureValue, 0, 6);

        $signedXml = $dom->saveXML();
        if ($signedXml === false) {
            throw new RuntimeException('No se pudo serializar el documento XML firmado.');
        }

        return [
            'xml_firmado'      => $signedXml,
            'digest_value'     => $digestValue,
            'signature_value'  => $signatureValue,
            'codigo_seguridad' => $codigoSeguridad,
            'cert_metadata'    => $creds['metadata'],
        ];
    }

    /**
     * Verifica matemáticamente un XML firmado (integridad SHA-256 del documento + firma RSA-SHA256 del certificado).
     * Usado tanto por pruebas locales como por el Mock Server DGII.
     */
    public function verifyXml(string $signedXml): array
    {
        $dom = new DOMDocument('1.0', 'UTF-8');
        $dom->preserveWhiteSpace = false;
        $dom->formatOutput = false;

        if (!@$dom->loadXML($signedXml)) {
            return ['valid' => false, 'error' => 'XML mal formado.'];
        }

        $xpath = new DOMXPath($dom);
        $xpath->registerNamespace('ds', self::XMLDSIG_NS);

        $signatureNode = $xpath->query('//ds:Signature')->item(0);
        $signedInfoNode = $xpath->query('//ds:Signature/ds:SignedInfo')->item(0);
        $digestValueNode = $xpath->query('//ds:Signature/ds:SignedInfo/ds:Reference/ds:DigestValue')->item(0);
        $sigValueNode = $xpath->query('//ds:Signature/ds:SignatureValue')->item(0);
        $certNode = $xpath->query('//ds:Signature/ds:KeyInfo/ds:X509Data/ds:X509Certificate')->item(0);

        if (!$signatureNode || !$signedInfoNode || !$digestValueNode || !$sigValueNode || !$certNode) {
            return ['valid' => false, 'error' => 'Estructura <Signature> XMLDSIG incompleta o ausente.'];
        }

        $expectedDigest = trim($digestValueNode->textContent);
        $signatureBase64 = preg_replace('/\s+/', '', $sigValueNode->textContent);
        $certBase64 = preg_replace('/\s+/', '', $certNode->textContent);

        // 1. Verificar firma RSA-SHA256 de <SignedInfo> usando la clave pública del X509Certificate embebido
        $canonicalSignedInfo = $signedInfoNode->C14N(false, false);
        $pemCert = "-----BEGIN CERTIFICATE-----\n" . chunk_split($certBase64, 64, "\n") . "-----END CERTIFICATE-----\n";
        $pubKey = openssl_pkey_get_public($pemCert);

        if ($pubKey === false) {
            return ['valid' => false, 'error' => 'El X509Certificate embebido en <KeyInfo> no es válido.'];
        }

        $rawSignature = base64_decode($signatureBase64, true);
        if ($rawSignature === false) {
            return ['valid' => false, 'error' => 'SignatureValue no es Base64 válido.'];
        }

        $rsaVerify = openssl_verify($canonicalSignedInfo, $rawSignature, $pubKey, OPENSSL_ALGO_SHA256);
        if ($rsaVerify !== 1) {
            return ['valid' => false, 'error' => 'La firma criptográfica RSA-SHA256 de <SignedInfo> no coincide.'];
        }

        // 2. Aplicar transformación enveloped-signature (remover <Signature>) y verificar DigestValue SHA-256
        $signatureNode->parentNode?->removeChild($signatureNode);
        $canonicalUnsigned = $dom->C14N(false, false);
        $actualDigest = base64_encode(hash('sha256', (string) $canonicalUnsigned, true));

        if (!hash_equals($expectedDigest, $actualDigest)) {
            return [
                'valid' => false,
                'error' => 'El DigestValue SHA-256 no coincide: el contenido del XML fue alterado después de firmar.',
            ];
        }

        $parsedCert = openssl_x509_parse($pemCert) ?: [];

        return [
            'valid'            => true,
            'codigo_seguridad' => substr($signatureBase64, 0, 6),
            'digest_value'     => $actualDigest,
            'subject_cn'       => $parsedCert['subject']['CN'] ?? null,
        ];
    }
}

