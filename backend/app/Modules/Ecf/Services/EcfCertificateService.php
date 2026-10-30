<?php

namespace App\Modules\Ecf\Services;

use App\Modules\Ecf\Models\EcfConfiguracion;
use RuntimeException;

class EcfCertificateService
{
    public function getOpenSslConfigPath(): string
    {
        return base_path('app/Modules/Ecf/Resources/openssl.cnf');
    }

    /**
     * Genera un certificado digital .p12 autofirmado RSA-2048 de prueba
     * compatible con el motor de firma XMLDSIG SHA-256 en local.
     */
    public function generateTestCertificate(
        ?string $outputPath = null,
        string $password = '1234',
        array $dnOverrides = [],
        int $validDays = 365
    ): array {
        $outputPath = $outputPath ?: storage_path('app/dgii/certs/certificado_prueba.p12');
        $dir = dirname($outputPath);

        if (!is_dir($dir) && !mkdir($dir, 0755, true) && !is_dir($dir)) {
            throw new RuntimeException("No se pudo crear el directorio de certificados: {$dir}");
        }

        $opensslConfig = [
            'config'           => $this->getOpenSslConfigPath(),
            'private_key_bits' => 2048,
            'private_key_type' => OPENSSL_KEYTYPE_RSA,
            'digest_alg'       => 'sha256',
        ];

        $dn = array_merge([
            'countryName'            => 'DO',
            'stateOrProvinceName'    => 'Santiago',
            'localityName'           => 'Santiago de los Caballeros',
            'organizationName'       => 'Menuxa LwaderSoft',
            'organizationalUnitName' => 'Facturacion Electronica POS',
            'commonName'             => 'PruebaFacturacionDGII',
        ], $dnOverrides);

        $privKey = openssl_pkey_new($opensslConfig);
        if ($privKey === false) {
            throw new RuntimeException('Error OpenSSL al generar clave privada RSA-2048: ' . $this->collectOpenSslErrors());
        }

        $csr = openssl_csr_new($dn, $privKey, $opensslConfig);
        if ($csr === false) {
            throw new RuntimeException('Error OpenSSL al crear CSR: ' . $this->collectOpenSslErrors());
        }

        $x509 = openssl_csr_sign($csr, null, $privKey, $validDays, $opensslConfig, time());
        if ($x509 === false) {
            throw new RuntimeException('Error OpenSSL al autofirmar certificado X.509: ' . $this->collectOpenSslErrors());
        }

        $pkcs12Content = '';
        $exported = openssl_pkcs12_export($x509, $pkcs12Content, $privKey, $password, $opensslConfig);
        if (!$exported) {
            throw new RuntimeException('Error OpenSSL al exportar contenedor .p12: ' . $this->collectOpenSslErrors());
        }

        if (file_put_contents($outputPath, $pkcs12Content) === false) {
            throw new RuntimeException("No se pudo guardar el archivo .p12 en: {$outputPath}");
        }

        return $this->inspectCertificate($outputPath, $password);
    }

    /**
     * Garantiza que exista un certificado disponible. En modo 'mock' lo auto-genera si aún no existe.
     */
    public function ensureCertificateReady(?EcfConfiguracion $config = null): array
    {
        $config = $config ?: EcfConfiguracion::obtenerActiva();
        $path = $config->getEffectiveCertPath();
        $password = $config->getPasswordPlain();

        if (!is_file($path)) {
            if ($config->ambiente === 'mock') {
                $this->generateTestCertificate($path, $password, [
                    'organizationName' => $config->razon_social ?: 'Menuxa POS',
                    'commonName'       => $config->rnc_limpio ?: 'PruebaFacturacionDGII',
                ]);
            } else {
                throw new RuntimeException("No se encontró el archivo de certificado digital (.p12) en: {$path}");
            }
        }

        return $this->loadCredentials($path, $password);
    }

    /**
     * Lee el contenedor .p12 y extrae clave privada, certificado PEM, X509 en Base64 limpio y metadatos.
     */
    public function loadCredentials(string $p12Path, string $password): array
    {
        if (!is_file($p12Path)) {
            throw new RuntimeException("El archivo de certificado .p12 no existe: {$p12Path}");
        }

        $rawPkcs12 = file_get_contents($p12Path);
        if ($rawPkcs12 === false || $rawPkcs12 === '') {
            throw new RuntimeException("No se pudo leer el contenido del certificado .p12: {$p12Path}");
        }

        $certs = [];
        if (!openssl_pkcs12_read($rawPkcs12, $certs, $password)) {
            throw new RuntimeException('No se pudo abrir el certificado .p12. Verifique la contraseña o el formato PKCS#12: ' . $this->collectOpenSslErrors());
        }

        if (empty($certs['pkey']) || empty($certs['cert'])) {
            throw new RuntimeException('El archivo .p12 no contiene la clave privada o el certificado X.509 requerido.');
        }

        $certPem = $certs['cert'];
        $cleanBase64Cert = preg_replace(
            '/-----BEGIN CERTIFICATE-----|-----END CERTIFICATE-----|\s+/',
            '',
            $certPem
        );

        $parsed = openssl_x509_parse($certPem) ?: [];
        $validFromTs = $parsed['validFrom_time_t'] ?? null;
        $validToTs = $parsed['validTo_time_t'] ?? null;
        $now = time();

        return [
            'path'          => $p12Path,
            'private_key'   => $certs['pkey'],
            'cert_pem'      => $certPem,
            'cert_base64'   => $cleanBase64Cert,
            'extracerts'    => $certs['extracerts'] ?? [],
            'metadata'      => [
                'existe'         => true,
                'valido'         => $validToTs ? ($validToTs > $now) : true,
                'expirado'       => $validToTs ? ($validToTs <= $now) : false,
                'dias_restantes' => $validToTs ? (int) floor(($validToTs - $now) / 86400) : null,
                'cn'             => $parsed['subject']['CN'] ?? 'Desconocido',
                'organizacion'   => $parsed['subject']['O'] ?? null,
                'emisor_ca'      => $parsed['issuer']['CN'] ?? ($parsed['issuer']['O'] ?? 'Autofirmado'),
                'serial'         => (string) ($parsed['serialNumberHex'] ?? ($parsed['serialNumber'] ?? '')),
                'valido_desde'   => $validFromTs ? date('Y-m-d H:i:s', $validFromTs) : null,
                'valido_hasta'   => $validToTs ? date('Y-m-d H:i:s', $validToTs) : null,
                'archivo'        => basename($p12Path),
            ],
        ];
    }

    /**
     * Inspecciona el estado del certificado sin lanzar excepción si no existe.
     */
    public function inspectCertificate(string $p12Path, string $password): array
    {
        try {
            $creds = $this->loadCredentials($p12Path, $password);
            return $creds['metadata'];
        } catch (\Throwable $e) {
            return [
                'existe'         => is_file($p12Path),
                'valido'         => false,
                'expirado'       => false,
                'dias_restantes' => 0,
                'cn'             => null,
                'organizacion'   => null,
                'emisor_ca'      => null,
                'serial'         => null,
                'valido_desde'   => null,
                'valido_hasta'   => null,
                'archivo'        => basename($p12Path),
                'error'          => $e->getMessage(),
            ];
        }
    }

    private function collectOpenSslErrors(): string
    {
        $errors = [];
        while ($msg = openssl_error_string()) {
            $errors[] = $msg;
        }
        return implode(' | ', $errors);
    }
}

