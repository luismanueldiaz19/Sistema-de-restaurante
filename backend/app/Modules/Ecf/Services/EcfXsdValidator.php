<?php

namespace App\Modules\Ecf\Services;

use DOMDocument;

class EcfXsdValidator
{
    /**
     * Valida un XML contra el esquema XSD correspondiente ('ECF', 'RFCE' o 'Semilla').
     * Busca primero si el usuario colocó los XSD oficiales de la DGII en storage/app/dgii/xsd/,
     * y en su defecto usa los XSD incluidos en app/Modules/Ecf/Resources/xsd/.
     */
    public function validate(string $xmlContent, ?string $tipoEcf = null): array
    {
        $dom = new DOMDocument('1.0', 'UTF-8');
        $dom->preserveWhiteSpace = false;

        $prevUseErrors = libxml_use_internal_errors(true);
        libxml_clear_errors();

        if (!$dom->loadXML($xmlContent)) {
            $errors = $this->formatLibXmlErrors(libxml_get_errors());
            libxml_clear_errors();
            libxml_use_internal_errors($prevUseErrors);

            return [
                'valid'  => false,
                'schema' => null,
                'errors' => $errors ?: ['Error de sintaxis al parsear el XML.'],
            ];
        }

        $rootName = $dom->documentElement?->localName ?? 'ECF';
        $xsdPath = $this->resolveSchemaPath($rootName, $tipoEcf);

        if (!$xsdPath || !is_file($xsdPath)) {
            libxml_use_internal_errors($prevUseErrors);
            return [
                'valid'  => false,
                'schema' => $xsdPath,
                'errors' => ["No se encontró el archivo de esquema XSD para {$rootName}."],
            ];
        }

        $isValid = $dom->schemaValidate($xsdPath);
        $errors = $isValid ? [] : $this->formatLibXmlErrors(libxml_get_errors());

        libxml_clear_errors();
        libxml_use_internal_errors($prevUseErrors);

        return [
            'valid'  => $isValid,
            'schema' => basename($xsdPath),
            'errors' => $errors,
        ];
    }

    private function resolveSchemaPath(string $rootName, ?string $tipoEcf): ?string
    {
        $customDir = storage_path('app/dgii/xsd');
        $bundledDir = base_path('app/Modules/Ecf/Resources/xsd');

        if ($rootName === 'RFCE') {
            $candidates = [
                "{$customDir}/RFCE 32 v.1.0.xsd",
                "{$customDir}/RFCE.xsd",
                "{$bundledDir}/RFCE.xsd",
            ];
        } elseif ($rootName === 'SemillaModel') {
            $candidates = [
                "{$customDir}/Semilla.xsd",
                "{$bundledDir}/Semilla.xsd",
            ];
        } else {
            $candidates = [];
            if ($tipoEcf) {
                $candidates[] = "{$customDir}/e-CF {$tipoEcf} v.1.0.xsd";
                $candidates[] = "{$customDir}/ECF_{$tipoEcf}.xsd";
            }
            $candidates[] = "{$customDir}/ECF.xsd";
            $candidates[] = "{$bundledDir}/ECF.xsd";
        }

        foreach ($candidates as $file) {
            if (is_file($file)) {
                return $file;
            }
        }

        return null;
    }

    private function formatLibXmlErrors(array $errors): array
    {
        $messages = [];
        foreach ($errors as $err) {
            $messages[] = sprintf('Línea %d: %s', $err->line, trim($err->message));
        }
        return $messages;
    }
}

