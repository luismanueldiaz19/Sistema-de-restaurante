<?php

namespace App\Modules\Ecf\Services;

class QrTimbreBuilder
{
    /**
     * Construye la URL oficial del Código QR de la DGII para la Representación Impresa (RI):
     * - Si es Factura de Consumo (32) < RD$ 250,000.00 -> ConsultaTimbreFC (4 parámetros)
     * - Para todos los demás casos (31, 33, 34, 44, 45, 46 y 32 >= 250,000) -> ConsultaTimbre (7 parámetros)
     */
    public function buildQrUrl(
        string $ambiente,
        string $tipoEcf,
        string $rncEmisor,
        ?string $rncComprador,
        string $encf,
        string $fechaEmisionDdMmYyyy,
        float $montoTotal,
        string $fechaHoraFirma,
        string $codigoSeguridad
    ): string {
        $endpoints = config("ecf.endpoints.{$ambiente}") ?? config('ecf.endpoints.mock');

        $rncEmisorClean = preg_replace('/[^0-9]/', '', $rncEmisor);
        $rncCompradorClean = preg_replace('/[^0-9]/', '', (string) $rncComprador);
        $montoFormatted = number_format(round($montoTotal, 2), 2, '.', '');

        $esResumenFc = ($tipoEcf === '32' && $montoTotal < 250000.00);

        if ($esResumenFc) {
            $baseUrl = $endpoints['timbre_fc_url'] ?? 'https://fc.dgii.gov.do/TesteCF/ConsultaTimbreFC';

            return sprintf(
                '%s?RncEmisor=%s&ENCF=%s&MontoTotal=%s&CodigoSeguridad=%s',
                $baseUrl,
                rawurlencode($rncEmisorClean),
                rawurlencode($encf),
                rawurlencode($montoFormatted),
                rawurlencode($codigoSeguridad)
            );
        }

        $baseUrl = $endpoints['timbre_url'] ?? 'https://ecf.dgii.gov.do/TesteCF/ConsultaTimbre';

        $params = [
            'RncEmisor=' . rawurlencode($rncEmisorClean),
        ];

        // En E32 >= 250k o E43 puede no haber RNC comprador válido; en E31/E34/E44/E45 sí se incluye
        if ($rncCompradorClean !== '' && !preg_match('/^0+$/', $rncCompradorClean)) {
            $params[] = 'RncComprador=' . rawurlencode($rncCompradorClean);
        }

        $params[] = 'ENCF=' . rawurlencode($encf);
        $params[] = 'FechaEmision=' . rawurlencode($fechaEmisionDdMmYyyy);
        $params[] = 'MontoTotal=' . rawurlencode($montoFormatted);
        $params[] = 'FechaFirma=' . rawurlencode($fechaHoraFirma);
        $params[] = 'CodigoSeguridad=' . rawurlencode($codigoSeguridad);

        return $baseUrl . '?' . implode('&', $params);
    }
}

