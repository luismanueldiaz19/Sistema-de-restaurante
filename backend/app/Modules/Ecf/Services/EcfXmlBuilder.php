<?php

namespace App\Modules\Ecf\Services;

use App\Models\Factura;
use App\Models\NotaCredito;
use App\Modules\Ecf\Models\EcfConfiguracion;
use Carbon\Carbon;
use DOMDocument;
use DOMElement;
use RuntimeException;

class EcfXmlBuilder
{
    /**
     * Construye el XML <ECF> oficial para una Factura (E31, E32, E44, E45, E46).
     */
    public function buildFromFactura(Factura $factura, EcfConfiguracion $config, string $fechaHoraFirma): array
    {
        $factura->loadMissing(['cliente', 'detalles.producto']);

        $encf = strtoupper(trim((string) $factura->ncf));
        if (!preg_match('/^E([0-9]{2})[0-9]{10}$/', $encf, $matches)) {
            throw new RuntimeException("El NCF '{$encf}' no tiene estructura electrónica válida de 13 caracteres (Ej: E320000000001).");
        }

        $tipoEcf = $matches[1];
        $fechaEmision = Carbon::parse($factura->fecha_emision ?? now())->format('d-m-Y');
        $esCredito = ((int) ($factura->dias_credito ?? 0)) > 0;
        $tipoPago = $esCredito ? '2' : '1';

        $rncEmisor = $this->sanitizeDigits($config->rnc_emisor, '40224129524');
        $rncComprador = $this->sanitizeDigits((string) ($factura->cliente?->rnc_cedula ?? ''));
        $razonSocialComprador = trim((string) ($factura->cliente?->nombre ?? 'CONSUMIDOR FINAL'));

        // Si el RNC es genérico 0000000000 en Consumo (32), lo tratamos como consumidor sin RNC
        if (preg_match('/^0+$/', $rncComprador)) {
            $rncComprador = '';
        }

        // En Crédito Fiscal (31) y Gubernamental (45), el RNC del comprador es obligatorio (9 u 11 dígitos)
        if (in_array($tipoEcf, ['31', '45'], true) && !in_array(strlen($rncComprador), [9, 11], true)) {
            throw new RuntimeException("El comprobante E{$tipoEcf} exige un RNC o Cédula válido (9 u 11 dígitos) del cliente.");
        }

        $dom = new DOMDocument('1.0', 'UTF-8');
        $dom->preserveWhiteSpace = false;
        $dom->formatOutput = false;

        $ecf = $dom->createElement('ECF');
        $dom->appendChild($ecf);

        $encabezado = $dom->createElement('Encabezado');
        $ecf->appendChild($encabezado);
        $this->appendText($dom, $encabezado, 'Version', '1.0');

        // ── 1. IdDoc ──────────────────────────────────────────────────────
        $idDoc = $dom->createElement('IdDoc');
        $encabezado->appendChild($idDoc);
        $this->appendText($dom, $idDoc, 'TipoeCF', $tipoEcf);
        $this->appendText($dom, $idDoc, 'eNCF', $encf);

        // FechaVencimientoSecuencia aplica a 31, 33, 44, 45, 46 (no a 32 ni 34 según Ficha Técnica DGII)
        if (!in_array($tipoEcf, ['32', '34'], true)) {
            $vencSecuencia = Carbon::parse($factura->fecha_emision ?? now())->endOfYear()->addYear()->format('d-m-Y');
            $this->appendText($dom, $idDoc, 'FechaVencimientoSecuencia', $vencSecuencia);
        }

        // IndicadorMontoGravado = 0 (los precios unitarios en el XML se expresan netos sin ITBIS)
        if (!in_array($tipoEcf, ['44', '46'], true)) {
            $this->appendText($dom, $idDoc, 'IndicadorMontoGravado', '0');
        }

        $this->appendText($dom, $idDoc, 'TipoIngresos', '01');
        $this->appendText($dom, $idDoc, 'TipoPago', $tipoPago);

        if ($esCredito && $factura->fecha_vencimiento) {
            $this->appendText($dom, $idDoc, 'FechaLimitePago', Carbon::parse($factura->fecha_vencimiento)->format('d-m-Y'));
        }

        // ── 2. Emisor ─────────────────────────────────────────────────────
        $this->buildEmisorBlock($dom, $encabezado, $config, $rncEmisor, $fechaEmision);

        // ── 3. Comprador ──────────────────────────────────────────────────
        if ($rncComprador !== '' || $tipoEcf !== '32') {
            $comprador = $dom->createElement('Comprador');
            $encabezado->appendChild($comprador);
            if ($rncComprador !== '') {
                $this->appendText($dom, $comprador, 'RNCComprador', $rncComprador);
            }
            $this->appendText($dom, $comprador, 'RazonSocialComprador', mb_substr($razonSocialComprador, 0, 150));
        }

        // ── 4. DetallesItems y Acumuladores de Totales ────────────────────
        $totalesSlot = $dom->createElement('Totales');
        $encabezado->appendChild($totalesSlot);

        $detallesItemsEl = $dom->createElement('DetallesItems');
        $ecf->appendChild($detallesItemsEl);

        $montoGravadoI1 = 0.0; // 18%
        $montoGravadoI2 = 0.0; // 16%
        $montoGravadoI3 = 0.0; // 0%
        $montoExento    = 0.0;
        $totalItbis1    = 0.0;
        $totalItbis2    = 0.0;

        $lineaNum = 1;
        foreach ($factura->detalles as $det) {
            $cantidad = max(0.01, (float) $det->cantidad);
            $itbisLinea = round((float) $det->itbis, 2);
            $totalLinea = round((float) $det->total, 2);
            $subtotalNetoLinea = round($totalLinea - $itbisLinea, 2);

            // Determinar tasa e IndicadorFacturacion (1=18%, 2=16%, 3=0%, 4=Exento)
            $indicadorFact = '4';
            if ($tipoEcf === '44') {
                $indicadorFact = '4'; // Régimen Especial exento
                $montoExento += $subtotalNetoLinea;
            } elseif ($tipoEcf === '46') {
                $indicadorFact = '3'; // Exportaciones tasa 0%
                $montoGravadoI3 += $subtotalNetoLinea;
            } elseif ($itbisLinea > 0.001 && $subtotalNetoLinea > 0) {
                $tasaAprox = ($itbisLinea / $subtotalNetoLinea) * 100;
                if (abs($tasaAprox - 16) < 1.5) {
                    $indicadorFact = '2';
                    $montoGravadoI2 += $subtotalNetoLinea;
                    $totalItbis2 += $itbisLinea;
                } else {
                    $indicadorFact = '1';
                    $montoGravadoI1 += $subtotalNetoLinea;
                    $totalItbis1 += $itbisLinea;
                }
            } else {
                $indicadorFact = '4';
                $montoExento += $subtotalNetoLinea;
            }

            $precioUnitarioNeto = $cantidad > 0 ? round($subtotalNetoLinea / $cantidad, 4) : 0.0;
            $esServicio = ($det->producto?->tipo_producto === 'SERVICIO') ? '2' : '1';
            $nombreItem = trim((string) ($det->descripcion ?: ($det->producto?->nombre ?: "ITEM {$lineaNum}")));

            $itemEl = $dom->createElement('Item');
            $detallesItemsEl->appendChild($itemEl);

            $this->appendText($dom, $itemEl, 'NumeroLinea', (string) $lineaNum);
            $this->appendText($dom, $itemEl, 'IndicadorFacturacion', $indicadorFact);
            $this->appendText($dom, $itemEl, 'NombreItem', mb_substr($nombreItem, 0, 80));
            $this->appendText($dom, $itemEl, 'IndicadorBienoServicio', $esServicio);
            $this->appendText($dom, $itemEl, 'CantidadItem', $this->fmt2($cantidad));
            $this->appendText($dom, $itemEl, 'PrecioUnitarioItem', $this->fmtPrice($precioUnitarioNeto));
            $this->appendText($dom, $itemEl, 'MontoItem', $this->fmt2($subtotalNetoLinea));

            $lineaNum++;
        }

        // ── 5. Completar Totales ──────────────────────────────────────────
        $montoGravadoI1 = round($montoGravadoI1, 2);
        $montoGravadoI2 = round($montoGravadoI2, 2);
        $montoGravadoI3 = round($montoGravadoI3, 2);
        $montoExento    = round($montoExento, 2);
        $totalItbis1    = round($totalItbis1, 2);
        $totalItbis2    = round($totalItbis2, 2);

        $montoGravadoTotal = round($montoGravadoI1 + $montoGravadoI2 + $montoGravadoI3, 2);
        $totalItbis        = round($totalItbis1 + $totalItbis2, 2);
        $montoTotal        = round($montoGravadoTotal + $montoExento + $totalItbis, 2);

        $this->populateTotales(
            $dom,
            $totalesSlot,
            $montoGravadoTotal,
            $montoGravadoI1,
            $montoGravadoI2,
            $montoGravadoI3,
            $montoExento,
            $totalItbis,
            $totalItbis1,
            $totalItbis2,
            $montoTotal
        );

        // ── 6. FechaHoraFirma ─────────────────────────────────────────────
        $this->appendText($dom, $ecf, 'FechaHoraFirma', $fechaHoraFirma);

        return [
            'xml'                    => (string) $dom->saveXML(),
            'encf'                   => $encf,
            'tipo_ecf'               => $tipoEcf,
            'rnc_emisor'             => $rncEmisor,
            'rnc_comprador'          => $rncComprador !== '' ? $rncComprador : null,
            'razon_social_comprador' => $razonSocialComprador,
            'fecha_emision_dgii'     => $fechaEmision,
            'fecha_emision_sql'      => Carbon::parse($factura->fecha_emision ?? now())->toDateString(),
            'monto_gravado'          => $montoGravadoTotal,
            'monto_exento'           => $montoExento,
            'monto_gravado_i1'       => $montoGravadoI1,
            'monto_gravado_i2'       => $montoGravadoI2,
            'monto_gravado_i3'       => $montoGravadoI3,
            'total_itbis'            => $totalItbis,
            'total_itbis1'           => $totalItbis1,
            'total_itbis2'           => $totalItbis2,
            'monto_total'            => $montoTotal,
            'tipo_pago'              => $tipoPago,
            'es_resumen_fc'          => ($tipoEcf === '32' && $montoTotal < 250000.00),
        ];
    }

    /**
     * Construye el XML <RFCE> (Resumen de Factura de Consumo Electrónica < RD$250,000.00)
     * incorporando el <CodigoSeguridadECF> extraído de la firma del <ECF> completo.
     */
    public function buildRfceXml(array $ecfBuildData, EcfConfiguracion $config, string $codigoSeguridadEcf): string
    {
        $dom = new DOMDocument('1.0', 'UTF-8');
        $dom->preserveWhiteSpace = false;
        $dom->formatOutput = false;

        $rfce = $dom->createElement('RFCE');
        $dom->appendChild($rfce);

        $encabezado = $dom->createElement('Encabezado');
        $rfce->appendChild($encabezado);
        $this->appendText($dom, $encabezado, 'Version', '1.0');

        $idDoc = $dom->createElement('IdDoc');
        $encabezado->appendChild($idDoc);
        $this->appendText($dom, $idDoc, 'TipoeCF', '32');
        $this->appendText($dom, $idDoc, 'eNCF', $ecfBuildData['encf']);
        $this->appendText($dom, $idDoc, 'TipoIngresos', '01');
        $this->appendText($dom, $idDoc, 'TipoPago', (string) $ecfBuildData['tipo_pago']);

        $emisor = $dom->createElement('Emisor');
        $encabezado->appendChild($emisor);
        $this->appendText($dom, $emisor, 'RNCEmisor', $ecfBuildData['rnc_emisor']);
        $this->appendText($dom, $emisor, 'RazonSocialEmisor', mb_substr($config->razon_social, 0, 150));
        $this->appendText($dom, $emisor, 'FechaEmision', $ecfBuildData['fecha_emision_dgii']);

        if (!empty($ecfBuildData['rnc_comprador'])) {
            $comprador = $dom->createElement('Comprador');
            $encabezado->appendChild($comprador);
            $this->appendText($dom, $comprador, 'RNCComprador', $ecfBuildData['rnc_comprador']);
            $this->appendText($dom, $comprador, 'RazonSocialComprador', mb_substr((string) $ecfBuildData['razon_social_comprador'], 0, 150));
        }

        $totales = $dom->createElement('Totales');
        $encabezado->appendChild($totales);

        if ($ecfBuildData['monto_gravado'] > 0) {
            $this->appendText($dom, $totales, 'MontoGravadoTotal', $this->fmt2($ecfBuildData['monto_gravado']));
        }
        if ($ecfBuildData['monto_gravado_i1'] > 0) {
            $this->appendText($dom, $totales, 'MontoGravado1', $this->fmt2($ecfBuildData['monto_gravado_i1']));
        }
        if ($ecfBuildData['monto_gravado_i2'] > 0) {
            $this->appendText($dom, $totales, 'MontoGravado2', $this->fmt2($ecfBuildData['monto_gravado_i2']));
        }
        if ($ecfBuildData['monto_gravado_i3'] > 0) {
            $this->appendText($dom, $totales, 'MontoGravado3', $this->fmt2($ecfBuildData['monto_gravado_i3']));
        }
        if ($ecfBuildData['monto_exento'] > 0 || $ecfBuildData['monto_gravado'] <= 0) {
            $this->appendText($dom, $totales, 'MontoExento', $this->fmt2($ecfBuildData['monto_exento']));
        }
        if ($ecfBuildData['total_itbis'] > 0) {
            $this->appendText($dom, $totales, 'TotalITBIS', $this->fmt2($ecfBuildData['total_itbis']));
        }
        if ($ecfBuildData['total_itbis1'] > 0) {
            $this->appendText($dom, $totales, 'TotalITBIS1', $this->fmt2($ecfBuildData['total_itbis1']));
        }
        if ($ecfBuildData['total_itbis2'] > 0) {
            $this->appendText($dom, $totales, 'TotalITBIS2', $this->fmt2($ecfBuildData['total_itbis2']));
        }

        $this->appendText($dom, $totales, 'MontoTotal', $this->fmt2($ecfBuildData['monto_total']));
        $this->appendText($dom, $encabezado, 'CodigoSeguridadECF', $codigoSeguridadEcf);

        return (string) $dom->saveXML();
    }

    /**
     * Construye el XML <ECF> oficial para una Nota de Crédito Electrónica (E34).
     */
    public function buildFromNotaCredito(NotaCredito $nota, EcfConfiguracion $config, string $fechaHoraFirma): array
    {
        $nota->loadMissing(['factura.cliente', 'detalles.producto']);
        $facturaOrig = $nota->factura;

        if (!$facturaOrig) {
            throw new RuntimeException('La Nota de Crédito no tiene factura original asociada.');
        }

        $encf = strtoupper(trim((string) $nota->ncf));
        if (!preg_match('/^E([0-9]{2})[0-9]{10}$/', $encf, $matches)) {
            throw new RuntimeException("El NCF de Nota de Crédito '{$encf}' no es un e-NCF válido (E34...).");
        }

        $tipoEcf = $matches[1]; // '34'
        $fechaEmisionCarbon = Carbon::parse($nota->created_at ?? now());
        $fechaOrigCarbon = Carbon::parse($facturaOrig->fecha_emision ?? now());
        $diasTranscurridos = $fechaOrigCarbon->diffInDays($fechaEmisionCarbon);
        $indicadorNotaCredito = $diasTranscurridos > 30 ? '1' : '0';

        $fechaEmision = $fechaEmisionCarbon->format('d-m-Y');
        $rncEmisor = $this->sanitizeDigits($config->rnc_emisor, '40224129524');
        $rncComprador = $this->sanitizeDigits((string) ($facturaOrig->cliente?->rnc_cedula ?? ''));
        if (preg_match('/^0+$/', $rncComprador)) {
            $rncComprador = '';
        }
        $razonSocialComprador = trim((string) ($facturaOrig->cliente?->nombre ?? 'CONSUMIDOR FINAL'));

        $dom = new DOMDocument('1.0', 'UTF-8');
        $dom->preserveWhiteSpace = false;
        $dom->formatOutput = false;

        $ecf = $dom->createElement('ECF');
        $dom->appendChild($ecf);

        $encabezado = $dom->createElement('Encabezado');
        $ecf->appendChild($encabezado);
        $this->appendText($dom, $encabezado, 'Version', '1.0');

        $idDoc = $dom->createElement('IdDoc');
        $encabezado->appendChild($idDoc);
        $this->appendText($dom, $idDoc, 'TipoeCF', $tipoEcf);
        $this->appendText($dom, $idDoc, 'eNCF', $encf);
        $this->appendText($dom, $idDoc, 'IndicadorNotaCredito', $indicadorNotaCredito);
        $this->appendText($dom, $idDoc, 'IndicadorMontoGravado', '0');
        $this->appendText($dom, $idDoc, 'TipoIngresos', '01');
        $this->appendText($dom, $idDoc, 'TipoPago', ((int) ($facturaOrig->dias_credito ?? 0)) > 0 ? '2' : '1');

        $this->buildEmisorBlock($dom, $encabezado, $config, $rncEmisor, $fechaEmision);

        if ($rncComprador !== '') {
            $comprador = $dom->createElement('Comprador');
            $encabezado->appendChild($comprador);
            $this->appendText($dom, $comprador, 'RNCComprador', $rncComprador);
            $this->appendText($dom, $comprador, 'RazonSocialComprador', mb_substr($razonSocialComprador, 0, 150));
        }

        $totalesSlot = $dom->createElement('Totales');
        $encabezado->appendChild($totalesSlot);

        $detallesItemsEl = $dom->createElement('DetallesItems');
        $ecf->appendChild($detallesItemsEl);

        $montoGravadoI1 = 0.0;
        $montoExento = 0.0;
        $totalItbis1 = 0.0;

        $lineaNum = 1;
        foreach ($nota->detalles as $det) {
            $cantidad = max(0.01, (float) $det->cantidad);
            $itbisLinea = round((float) $det->itbis, 2);
            $subtotalNeto = round((float) $det->subtotal, 2);

            if ($itbisLinea > 0.001) {
                $indicadorFact = '1';
                $montoGravadoI1 += $subtotalNeto;
                $totalItbis1 += $itbisLinea;
            } else {
                $indicadorFact = '4';
                $montoExento += $subtotalNeto;
            }

            $precioUnitarioNeto = $cantidad > 0 ? round($subtotalNeto / $cantidad, 4) : 0.0;
            $nombreItem = trim((string) ($det->producto?->nombre ?? "DEVOLUCION ITEM {$lineaNum}"));

            $itemEl = $dom->createElement('Item');
            $detallesItemsEl->appendChild($itemEl);
            $this->appendText($dom, $itemEl, 'NumeroLinea', (string) $lineaNum);
            $this->appendText($dom, $itemEl, 'IndicadorFacturacion', $indicadorFact);
            $this->appendText($dom, $itemEl, 'NombreItem', mb_substr($nombreItem, 0, 80));
            $this->appendText($dom, $itemEl, 'IndicadorBienoServicio', ($det->producto?->tipo_producto === 'SERVICIO') ? '2' : '1');
            $this->appendText($dom, $itemEl, 'CantidadItem', $this->fmt2($cantidad));
            $this->appendText($dom, $itemEl, 'PrecioUnitarioItem', $this->fmtPrice($precioUnitarioNeto));
            $this->appendText($dom, $itemEl, 'MontoItem', $this->fmt2($subtotalNeto));

            $lineaNum++;
        }

        $montoGravadoI1 = round($montoGravadoI1, 2);
        $montoExento = round($montoExento, 2);
        $totalItbis1 = round($totalItbis1, 2);
        $montoTotal = round($montoGravadoI1 + $montoExento + $totalItbis1, 2);

        $this->populateTotales(
            $dom,
            $totalesSlot,
            $montoGravadoI1,
            $montoGravadoI1,
            0.0,
            0.0,
            $montoExento,
            $totalItbis1,
            $totalItbis1,
            0.0,
            $montoTotal
        );

        // ── InformacionReferencia (obligatoria en E34) ────────────────────
        $esAnulacionTotal = abs($montoTotal - (float) $facturaOrig->total) < 0.05;
        $infoRef = $dom->createElement('InformacionReferencia');
        $ecf->appendChild($infoRef);
        $this->appendText($dom, $infoRef, 'NCFModificado', strtoupper((string) $facturaOrig->ncf));
        $this->appendText($dom, $infoRef, 'FechaNCFModificado', $fechaOrigCarbon->format('d-m-Y'));
        $this->appendText($dom, $infoRef, 'CodigoModificacion', $esAnulacionTotal ? '1' : '3');
        $this->appendText($dom, $infoRef, 'RazonModificacion', mb_substr(trim((string) ($nota->motivo ?: 'Devolución de mercancía')), 0, 90));

        $this->appendText($dom, $ecf, 'FechaHoraFirma', $fechaHoraFirma);

        return [
            'xml'                    => (string) $dom->saveXML(),
            'encf'                   => $encf,
            'tipo_ecf'               => $tipoEcf,
            'rnc_emisor'             => $rncEmisor,
            'rnc_comprador'          => $rncComprador !== '' ? $rncComprador : null,
            'razon_social_comprador' => $razonSocialComprador,
            'fecha_emision_dgii'     => $fechaEmision,
            'fecha_emision_sql'      => $fechaEmisionCarbon->toDateString(),
            'monto_gravado'          => $montoGravadoI1,
            'monto_exento'           => $montoExento,
            'total_itbis'            => $totalItbis1,
            'monto_total'            => $montoTotal,
            'es_resumen_fc'          => false,
        ];
    }

    private function buildEmisorBlock(
        DOMDocument $dom,
        DOMElement $encabezado,
        EcfConfiguracion $config,
        string $rncEmisor,
        string $fechaEmision
    ): void {
        $emisor = $dom->createElement('Emisor');
        $encabezado->appendChild($emisor);

        $this->appendText($dom, $emisor, 'RNCEmisor', $rncEmisor);
        $this->appendText($dom, $emisor, 'RazonSocialEmisor', mb_substr($config->razon_social ?: 'EMPRESA EMISORA', 0, 150));

        if (!empty($config->nombre_comercial)) {
            $this->appendText($dom, $emisor, 'NombreComercial', mb_substr($config->nombre_comercial, 0, 150));
        }

        $this->appendText($dom, $emisor, 'DireccionEmisor', mb_substr($config->direccion ?: 'REPUBLICA DOMINICANA', 0, 100));

        if (!empty($config->municipio)) {
            $this->appendText($dom, $emisor, 'Municipio', $config->municipio);
        }
        if (!empty($config->provincia)) {
            $this->appendText($dom, $emisor, 'Provincia', $config->provincia);
        }
        if (!empty($config->correo)) {
            $this->appendText($dom, $emisor, 'CorreoEmisor', mb_substr($config->correo, 0, 80));
        }
        if (!empty($config->sitio_web)) {
            $this->appendText($dom, $emisor, 'WebSite', mb_substr($config->sitio_web, 0, 100));
        }

        $this->appendText($dom, $emisor, 'FechaEmision', $fechaEmision);
    }

    private function populateTotales(
        DOMDocument $dom,
        DOMElement $totales,
        float $montoGravadoTotal,
        float $montoGravadoI1,
        float $montoGravadoI2,
        float $montoGravadoI3,
        float $montoExento,
        float $totalItbis,
        float $totalItbis1,
        float $totalItbis2,
        float $montoTotal
    ): void {
        if ($montoGravadoTotal > 0) {
            $this->appendText($dom, $totales, 'MontoGravadoTotal', $this->fmt2($montoGravadoTotal));
        }
        if ($montoGravadoI1 > 0) {
            $this->appendText($dom, $totales, 'MontoGravadoI1', $this->fmt2($montoGravadoI1));
        }
        if ($montoGravadoI2 > 0) {
            $this->appendText($dom, $totales, 'MontoGravadoI2', $this->fmt2($montoGravadoI2));
        }
        if ($montoGravadoI3 > 0) {
            $this->appendText($dom, $totales, 'MontoGravadoI3', $this->fmt2($montoGravadoI3));
        }
        if ($montoExento > 0 || $montoGravadoTotal <= 0) {
            $this->appendText($dom, $totales, 'MontoExento', $this->fmt2($montoExento));
        }
        if ($montoGravadoI1 > 0) {
            $this->appendText($dom, $totales, 'ITBIS1', '18');
        }
        if ($montoGravadoI2 > 0) {
            $this->appendText($dom, $totales, 'ITBIS2', '16');
        }
        if ($montoGravadoI3 > 0) {
            $this->appendText($dom, $totales, 'ITBIS3', '0');
        }
        if ($totalItbis > 0 || $montoGravadoTotal > 0) {
            $this->appendText($dom, $totales, 'TotalITBIS', $this->fmt2($totalItbis));
        }
        if ($montoGravadoI1 > 0) {
            $this->appendText($dom, $totales, 'TotalITBIS1', $this->fmt2($totalItbis1));
        }
        if ($montoGravadoI2 > 0) {
            $this->appendText($dom, $totales, 'TotalITBIS2', $this->fmt2($totalItbis2));
        }
        if ($montoGravadoI3 > 0) {
            $this->appendText($dom, $totales, 'TotalITBIS3', '0.00');
        }

        $this->appendText($dom, $totales, 'MontoTotal', $this->fmt2($montoTotal));
    }

    private function appendText(DOMDocument $dom, DOMElement $parent, string $tagName, string $value): void
    {
        $el = $dom->createElement($tagName);
        $el->appendChild($dom->createTextNode($value));
        $parent->appendChild($el);
    }

    private function sanitizeDigits(?string $raw, string $default = ''): string
    {
        $clean = preg_replace('/[^0-9]/', '', (string) $raw);
        return $clean !== '' ? $clean : $default;
    }

    private function fmt2(float $val): string
    {
        return number_format(round($val, 2), 2, '.', '');
    }

    private function fmtPrice(float $val): string
    {
        $rounded4 = round($val, 4);
        if (abs($rounded4 - round($val, 2)) < 0.0001) {
            return number_format($rounded4, 2, '.', '');
        }
        return rtrim(rtrim(number_format($rounded4, 4, '.', ''), '0'), '.');
    }
}

