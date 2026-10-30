<?php

namespace App\Modules\Ecf\Services;

use App\Modules\Ecf\Models\EcfConfiguracion;
use Carbon\Carbon;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Http;
use RuntimeException;

/**
 * Cliente de transporte hacia la DGII (Soporta 'mock' local sin bloqueo de hilos,
 * 'TesteCF' Sandbox, 'CerteCF' Certificación y 'eCF' Producción).
 */
class DgiiApiClient
{
    public function __construct(
        private readonly XmlDsigSigner $signer,
        private readonly DgiiMockService $mockService
    ) {}

    /**
     * Ejecuta el flujo completo de autenticación (Semilla -> Firma con .p12 -> Token Bearer)
     * y devuelve el token de sesión activo.
     */
    public function obtenerToken(?EcfConfiguracion $config = null, bool $forceRefresh = false): array
    {
        $config = $config ?: EcfConfiguracion::obtenerActiva();
        $ambiente = $config->ambiente ?: 'mock';
        $cacheKey = "dgii_ecf_active_token:{$ambiente}:{$config->rnc_limpio}";

        if (!$forceRefresh && Cache::has($cacheKey)) {
            return Cache::get($cacheKey);
        }

        $p12Path = $config->getEffectiveCertPath();
        $p12Pass = $config->getPasswordPlain();

        // 1. Obtener XML de Semilla
        if ($ambiente === 'mock') {
            $semillaXml = $this->mockService->generarSemillaXml();
        } else {
            $baseUrl = $this->getBaseUrl($ambiente, 'ecf_base');
            $respSemilla = Http::timeout(20)
                ->accept('application/xml, text/xml')
                ->get("{$baseUrl}/autenticacion/api/Autenticacion/Semilla");

            if (!$respSemilla->successful()) {
                throw new RuntimeException("Error HTTP {$respSemilla->status()} obteniendo semilla DGII ({$ambiente}).");
            }
            $semillaXml = $respSemilla->body();
        }

        // 2. Firmar la Semilla con nuestro motor XMLDSIG SHA-256 y certificado .p12
        $firmaSemilla = $this->signer->signXml($semillaXml, $p12Path, $p12Pass);
        $semillaFirmadaXml = $firmaSemilla['xml_firmado'];

        // 3. Enviar semilla firmada para obtener Token Bearer
        if ($ambiente === 'mock') {
            $tokenPayload = $this->mockService->validarSemillaFirmada($semillaFirmadaXml);
        } else {
            $baseUrl = $this->getBaseUrl($ambiente, 'ecf_base');
            $respToken = Http::timeout(25)
                ->attach('xml', $semillaFirmadaXml, 'semilla_firmada.xml', ['Content-Type' => 'text/xml'])
                ->post("{$baseUrl}/autenticacion/api/Autenticacion/ValidarSemilla");

            if (!$respToken->successful()) {
                throw new RuntimeException("Error HTTP {$respToken->status()} validando semilla en DGII: " . $respToken->body());
            }
            $tokenPayload = $respToken->json() ?: [];
        }

        if (empty($tokenPayload['token'])) {
            throw new RuntimeException('La respuesta de autenticación DGII no devolvió un token válido.');
        }

        $expiraAt = !empty($tokenPayload['expira'])
            ? Carbon::parse($tokenPayload['expira'])->subMinutes(2)
            : now()->addMinutes(50);

        if ($expiraAt->isPast()) {
            $expiraAt = now()->addMinutes(50);
        }

        $result = [
            'token'            => $tokenPayload['token'],
            'expira'           => $tokenPayload['expira'] ?? $expiraAt->toIso8601String(),
            'ambiente'         => $ambiente,
            'semilla_firmada'  => true,
            'cert_metadata'    => $firmaSemilla['cert_metadata'] ?? null,
        ];

        Cache::put($cacheKey, $result, $expiraAt);

        return $result;
    }

    /**
     * Envía un e-CF completo firmado (E31, E33, E34, E44, E45, E46 o E32 >= 250,000).
     */
    public function enviarEcf(string $signedEcfXml, string $encf, ?EcfConfiguracion $config = null): array
    {
        $config = $config ?: EcfConfiguracion::obtenerActiva();
        $ambiente = $config->ambiente ?: 'mock';
        $auth = $this->obtenerToken($config);
        $token = $auth['token'];

        if ($ambiente === 'mock') {
            return $this->mockService->recibirEcf($signedEcfXml, $token);
        }

        $baseUrl = $this->getBaseUrl($ambiente, 'ecf_base');
        $fileName = "{$config->rnc_limpio}{$encf}.xml";

        $response = Http::timeout(30)
            ->withToken($token)
            ->attach('xml', $signedEcfXml, $fileName, ['Content-Type' => 'text/xml'])
            ->post("{$baseUrl}/recepcion/api/FacturasElectronicas");

        if (!$response->successful() && $response->status() >= 500) {
            throw new RuntimeException("Error HTTP {$response->status()} al enviar e-CF a DGII: " . $response->body());
        }

        return $response->json() ?: [
            'estado' => 'En Proceso',
            'raw'    => $response->body(),
        ];
    }

    /**
     * Envía un Resumen de Factura de Consumo (<RFCE>) cuando es E32 < RD$250,000.00.
     */
    public function enviarRfce(string $signedRfceXml, string $encf, ?EcfConfiguracion $config = null): array
    {
        $config = $config ?: EcfConfiguracion::obtenerActiva();
        $ambiente = $config->ambiente ?: 'mock';
        $auth = $this->obtenerToken($config);
        $token = $auth['token'];

        if ($ambiente === 'mock') {
            return $this->mockService->recibirRfce($signedRfceXml, $token);
        }

        $fcBaseUrl = $this->getBaseUrl($ambiente, 'fc_base');
        $fileName = "{$config->rnc_limpio}{$encf}.xml";

        $response = Http::timeout(30)
            ->withToken($token)
            ->attach('xml', $signedRfceXml, $fileName, ['Content-Type' => 'text/xml'])
            ->post("{$fcBaseUrl}/recepcionfc/api/Recepcion/ecf");

        if (!$response->successful() && $response->status() >= 500) {
            throw new RuntimeException("Error HTTP {$response->status()} al enviar RFCE a DGII: " . $response->body());
        }

        return $response->json() ?: [
            'estado' => 'En Proceso',
            'raw'    => $response->body(),
        ];
    }

    /**
     * Consulta el resultado de procesamiento de un comprobante por su TrackId.
     */
    public function consultarEstadoTrackId(string $trackId, ?EcfConfiguracion $config = null): array
    {
        $config = $config ?: EcfConfiguracion::obtenerActiva();
        $ambiente = $config->ambiente ?: 'mock';
        $auth = $this->obtenerToken($config);
        $token = $auth['token'];

        if ($ambiente === 'mock') {
            return $this->mockService->consultarTrackId($trackId, $token);
        }

        $baseUrl = $this->getBaseUrl($ambiente, 'ecf_base');
        $response = Http::timeout(20)
            ->withToken($token)
            ->get("{$baseUrl}/consultaresultado/api/Consultas/Estado", [
                'trackId' => $trackId,
            ]);

        if (!$response->successful()) {
            throw new RuntimeException("Error HTTP {$response->status()} consultando TrackId en DGII.");
        }

        return $response->json() ?: [];
    }

    private function getBaseUrl(string $ambiente, string $key): string
    {
        $endpoints = config("ecf.endpoints.{$ambiente}") ?? config('ecf.endpoints.TesteCF');
        return rtrim((string) ($endpoints[$key] ?? ''), '/');
    }
}

