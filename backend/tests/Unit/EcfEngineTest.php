<?php

namespace Tests\Unit;

use App\Models\Cliente;
use App\Models\Factura;
use App\Models\FacturaDetalle;
use App\Modules\Ecf\Models\EcfConfiguracion;
use App\Modules\Ecf\Services\DgiiApiClient;
use App\Modules\Ecf\Services\EcfCertificateService;
use App\Modules\Ecf\Services\EcfXmlBuilder;
use App\Modules\Ecf\Services\EcfXsdValidator;
use App\Modules\Ecf\Services\QrTimbreBuilder;
use App\Modules\Ecf\Services\XmlDsigSigner;
use Illuminate\Support\Collection;
use Tests\TestCase;

class EcfEngineTest extends TestCase
{
    private function makeDummyConfig(): EcfConfiguracion
    {
        $config = new EcfConfiguracion([
            'ambiente'         => 'mock',
            'rnc_emisor'       => '40224129524',
            'razon_social'     => 'MENUXA RESTAURANTE SRL',
            'nombre_comercial' => 'MENUXA',
            'direccion'        => 'Av. Juan Pablo Duarte #45, Santiago',
            'municipio'        => '250100',
            'provincia'        => '250000',
            'correo'           => 'facturacion@menuxa.com',
            'sitio_web'        => 'www.menuxa.com',
            'certificado_path' => storage_path('app/dgii/certs/certificado_prueba.p12'),
            'envio_automatico' => true,
            'activo'           => true,
        ]);
        $config->setPasswordPlain('1234');

        return $config;
    }

    public function test_certificate_and_dgii_mock_authentication_handshake(): void
    {
        /** @var EcfCertificateService $certService */
        $certService = app(EcfCertificateService::class);
        $config = $this->makeDummyConfig();

        $creds = $certService->ensureCertificateReady($config);
        $this->assertTrue($creds['metadata']['valido']);
        $this->assertNotEmpty($creds['cert_base64']);

        /** @var DgiiApiClient $apiClient */
        $apiClient = app(DgiiApiClient::class);
        $tokenData = $apiClient->obtenerToken($config, true);

        $this->assertNotEmpty($tokenData['token']);
        $this->assertEquals('mock', $tokenData['ambiente']);
        $this->assertTrue($tokenData['semilla_firmada']);
    }

    public function test_xmldsig_signature_and_tamper_detection(): void
    {
        /** @var XmlDsigSigner $signer */
        $signer = app(XmlDsigSigner::class);
        $config = $this->makeDummyConfig();

        $rawXml = '<?xml version="1.0" encoding="UTF-8"?><SemillaModel><valor>abc123xyz</valor><fecha>2026-10-30T12:00:00Z</fecha></SemillaModel>';
        $signed = $signer->signXml($rawXml, $config->getEffectiveCertPath(), $config->getPasswordPlain());

        $this->assertEquals(6, strlen($signed['codigo_seguridad']));
        $this->assertStringContainsString('<Signature xmlns="http://www.w3.org/2000/09/xmldsig#">', $signed['xml_firmado']);

        // Verificación criptográfica legítima debe pasar
        $verified = $signer->verifyXml($signed['xml_firmado']);
        $this->assertTrue($verified['valid']);
        $this->assertEquals($signed['codigo_seguridad'], $verified['codigo_seguridad']);

        // Alterar 1 carácter del contenido después de firmado debe invalidar el DigestValue SHA-256
        $tamperedXml = str_replace('abc123xyz', 'abc123xyZ', $signed['xml_firmado']);
        $tamperCheck = $signer->verifyXml($tamperedXml);
        $this->assertFalse($tamperCheck['valid']);
    }

    public function test_e31_credito_fiscal_xml_xsd_signature_qr_and_mock_submission(): void
    {
        $config = $this->makeDummyConfig();

        $cliente = new Cliente([
            'nombre'     => 'CORPORACION DOMINICANA SRL',
            'rnc_cedula' => '131-45678-9',
        ]);

        $factura = new Factura([
            'ncf'             => 'E310000000001',
            'tipo_factura'    => 'Crédito Fiscal',
            'dias_credito'    => 0,
            'fecha_emision'   => '2026-10-30',
            'subtotal'        => 1000.00,
            'descuento_total' => 0.00,
            'itbis'           => 180.00,
            'total'           => 1180.00,
        ]);
        $factura->id = 999;
        $factura->setRelation('cliente', $cliente);

        $det1 = new FacturaDetalle();
        $det1->forceFill([
            'descripcion' => 'PLATO EJECUTIVO GOURMET & BEBIDA',
            'cantidad'    => 2,
            'precio'      => 590.00,
            'itbis'       => 180.00,
            'total'       => 1180.00,
        ]);
        $det1->setRelation('producto', null);
        $factura->setRelation('detalles', new Collection([$det1]));

        /** @var EcfXmlBuilder $builder */
        $builder = app(EcfXmlBuilder::class);
        $fechaFirma = '30-10-2026 11:45:00';
        $build = $builder->buildFromFactura($factura, $config, $fechaFirma);

        $this->assertFalse($build['es_resumen_fc']);
        $this->assertEquals(1180.00, $build['monto_total']);

        /** @var XmlDsigSigner $signer */
        $signer = app(XmlDsigSigner::class);
        $firma = $signer->signXml($build['xml'], $config->getEffectiveCertPath(), $config->getPasswordPlain());

        /** @var EcfXsdValidator $xsd */
        $xsd = app(EcfXsdValidator::class);
        $xsdResult = $xsd->validate($firma['xml_firmado'], '31');
        $this->assertTrue($xsdResult['valid'], 'Errores XSD E31: ' . implode(' | ', $xsdResult['errors']));

        /** @var QrTimbreBuilder $qr */
        $qr = app(QrTimbreBuilder::class);
        $qrUrl = $qr->buildQrUrl(
            'mock',
            '31',
            $build['rnc_emisor'],
            $build['rnc_comprador'],
            $build['encf'],
            $build['fecha_emision_dgii'],
            $build['monto_total'],
            $fechaFirma,
            $firma['codigo_seguridad']
        );

        $this->assertStringContainsString('ConsultaTimbre?RncEmisor=40224129524&RncComprador=131456789&ENCF=E310000000001', $qrUrl);
        $this->assertStringContainsString('CodigoSeguridad=' . rawurlencode($firma['codigo_seguridad']), $qrUrl);

        /** @var DgiiApiClient $client */
        $client = app(DgiiApiClient::class);
        $resp = $client->enviarEcf($firma['xml_firmado'], 'E310000000001', $config);

        $this->assertEquals('Aceptado', $resp['estado']);
        $this->assertNotEmpty($resp['trackId']);
    }

    public function test_e32_consumo_menor_250k_generates_rfce_and_consultatimbrefc_qr(): void
    {
        $config = $this->makeDummyConfig();

        $cliente = new Cliente([
            'nombre'     => 'Generico',
            'rnc_cedula' => '000-0000000-0',
        ]);

        $factura = new Factura([
            'ncf'           => 'E320000000005',
            'tipo_factura'  => 'Factura de Consumo',
            'dias_credito'  => 0,
            'fecha_emision' => '2026-10-30',
            'subtotal'      => 500.00,
            'itbis'         => 90.00,
            'total'         => 590.00,
        ]);
        $factura->id = 1000;
        $factura->setRelation('cliente', $cliente);

        $det = new FacturaDetalle();
        $det->forceFill([
            'descripcion' => 'COMBO HAMBURGUESA ESPECIAL',
            'cantidad'    => 1,
            'precio'      => 590.00,
            'itbis'       => 90.00,
            'total'       => 590.00,
        ]);
        $det->setRelation('producto', null);
        $factura->setRelation('detalles', new Collection([$det]));

        /** @var EcfXmlBuilder $builder */
        $builder = app(EcfXmlBuilder::class);
        /** @var XmlDsigSigner $signer */
        $signer = app(XmlDsigSigner::class);
        /** @var EcfXsdValidator $xsd */
        $xsd = app(EcfXsdValidator::class);

        $fechaFirma = '30-10-2026 11:50:00';
        $build = $builder->buildFromFactura($factura, $config, $fechaFirma);
        $this->assertTrue($build['es_resumen_fc']);

        $firmaEcf = $signer->signXml($build['xml'], $config->getEffectiveCertPath(), $config->getPasswordPlain());
        $this->assertTrue($xsd->validate($firmaEcf['xml_firmado'], '32')['valid']);

        // Construir y firmar RFCE con el CodigoSeguridadECF del ECF completo
        $rfceXml = $builder->buildRfceXml($build, $config, $firmaEcf['codigo_seguridad']);
        $firmaRfce = $signer->signXml($rfceXml, $config->getEffectiveCertPath(), $config->getPasswordPlain());
        $xsdRfce = $xsd->validate($firmaRfce['xml_firmado'], '32');
        $this->assertTrue($xsdRfce['valid'], 'Errores XSD RFCE: ' . implode(' | ', $xsdRfce['errors']));

        /** @var QrTimbreBuilder $qr */
        $qr = app(QrTimbreBuilder::class);
        $qrUrl = $qr->buildQrUrl(
            'mock',
            '32',
            $build['rnc_emisor'],
            $build['rnc_comprador'],
            $build['encf'],
            $build['fecha_emision_dgii'],
            $build['monto_total'],
            $fechaFirma,
            $firmaEcf['codigo_seguridad']
        );

        $this->assertStringContainsString('ConsultaTimbreFC?RncEmisor=40224129524&ENCF=E320000000005&MontoTotal=590.00&CodigoSeguridad=', $qrUrl);

        /** @var DgiiApiClient $client */
        $client = app(DgiiApiClient::class);
        $resp = $client->enviarRfce($firmaRfce['xml_firmado'], 'E320000000005', $config);
        $this->assertEquals('Aceptado', $resp['estado']);
    }
}

