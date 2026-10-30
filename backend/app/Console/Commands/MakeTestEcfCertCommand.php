<?php

namespace App\Console\Commands;

use App\Modules\Ecf\Models\EcfConfiguracion;
use App\Modules\Ecf\Services\EcfCertificateService;
use Illuminate\Console\Command;

class MakeTestEcfCertCommand extends Command
{
    protected $signature = 'ecf:make-test-cert
                            {--password=1234 : Contraseña para empaquetar el archivo .p12}
                            {--days=365 : Días de vigencia del certificado de prueba}';

    protected $description = 'Genera un certificado digital .p12 RSA-2048 autofirmado de prueba para firmar e-CF DGII en local';

    public function handle(EcfCertificateService $certService): int
    {
        $password = (string) $this->option('password');
        $days = (int) $this->option('days');
        $outputPath = storage_path('app/dgii/certs/certificado_prueba.p12');

        $this->info('Generando par de claves RSA-2048 y certificado .p12 autofirmado...');

        try {
            $config = EcfConfiguracion::obtenerActiva();

            $meta = $certService->generateTestCertificate($outputPath, $password, [
                'organizationName' => $config->razon_social ?: 'Menuxa LwaderSoft',
                'commonName'       => $config->rnc_limpio ?: 'PruebaFacturacionDGII',
            ], $days);

            if ($config->exists) {
                $config->certificado_path = $outputPath;
                $config->setPasswordPlain($password);
                $config->save();
            }

            $this->info("Certificado .p12 generado con éxito en: {$outputPath}");
            $this->table(
                ['Campo', 'Valor'],
                [
                    ['CN (Sujeto)', $meta['cn'] ?? '-'],
                    ['Organización', $meta['organizacion'] ?? '-'],
                    ['Válido Desde', $meta['valido_desde'] ?? '-'],
                    ['Válido Hasta', $meta['valido_hasta'] ?? '-'],
                    ['Días Restantes', (string) ($meta['dias_restantes'] ?? '-')],
                ]
            );

            return self::SUCCESS;
        } catch (\Throwable $e) {
            $this->error('Error al generar certificado .p12: ' . $e->getMessage());
            return self::FAILURE;
        }
    }
}

