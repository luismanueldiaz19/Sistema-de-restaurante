<?php

return [
    /*
    |--------------------------------------------------------------------------
    | Ambiente de Facturación Electrónica (DGII e-CF)
    |--------------------------------------------------------------------------
    | Valores soportados:
    | - 'mock'    : Simulador local 100% offline integrado en Laravel (por defecto)
    | - 'TesteCF' : Pre-Certificación / Sandbox oficial DGII
    | - 'CerteCF' : Certificación oficial DGII
    | - 'eCF'     : Producción oficial DGII
    */
    'ambiente' => env('DGII_ECF_ENV', 'mock'),

    /*
    |--------------------------------------------------------------------------
    | Datos Fiscales del Emisor (Valores por defecto si no se han editado en BD)
    |--------------------------------------------------------------------------
    */
    'emisor' => [
        'rnc'              => env('DGII_EMISOR_RNC', '40224129524'),
        'razon_social'     => env('DGII_EMISOR_RAZON_SOCIAL', 'MENUXA RESTAURANTE SRL'),
        'nombre_comercial' => env('DGII_EMISOR_NOMBRE_COMERCIAL', 'MENUXA'),
        'direccion'        => env('DGII_EMISOR_DIRECCION', 'Av. Juan Pablo Duarte, Centro Ciudad'),
        'municipio'        => env('DGII_EMISOR_MUNICIPIO', '250100'),
        'provincia'        => env('DGII_EMISOR_PROVINCIA', '250000'),
        'telefono'         => env('DGII_EMISOR_TELEFONO', '809-769-9580'),
        'correo'           => env('DGII_EMISOR_CORREO', '--'),
        'web'              => env('DGII_EMISOR_WEB', '--'),
    ],

    /*
    |--------------------------------------------------------------------------
    | Certificado Digital (.p12 / .pfx)
    |--------------------------------------------------------------------------
    */
    'certificado' => [
        'path'     => env('DGII_CERT_PATH', storage_path('app/dgii/certs/certificado_prueba.p12')),
        'password' => env('DGII_CERT_PASSWORD', '1234'),
    ],

    /*
    |--------------------------------------------------------------------------
    | Endpoints Oficiales DGII por Ambiente
    |--------------------------------------------------------------------------
    */
    'endpoints' => [
        'TesteCF' => [
            'ecf_base'       => 'https://ecf.dgii.gov.do/TesteCF',
            'fc_base'        => 'https://fc.dgii.gov.do/TesteCF',
            'timbre_url'     => 'https://ecf.dgii.gov.do/TesteCF/ConsultaTimbre',
            'timbre_fc_url'  => 'https://fc.dgii.gov.do/TesteCF/ConsultaTimbreFC',
        ],
        'CerteCF' => [
            'ecf_base'       => 'https://ecf.dgii.gov.do/CerteCF',
            'fc_base'        => 'https://fc.dgii.gov.do/CerteCF',
            'timbre_url'     => 'https://ecf.dgii.gov.do/CerteCF/ConsultaTimbre',
            'timbre_fc_url'  => 'https://fc.dgii.gov.do/CerteCF/ConsultaTimbreFC',
        ],
        'eCF' => [
            'ecf_base'       => 'https://ecf.dgii.gov.do/eCF',
            'fc_base'        => 'https://fc.dgii.gov.do/eCF',
            'timbre_url'     => 'https://ecf.dgii.gov.do/eCF/ConsultaTimbre',
            'timbre_fc_url'  => 'https://fc.dgii.gov.do/eCF/ConsultaTimbreFC',
        ],
        'mock' => [
            'ecf_base'       => env('APP_URL', 'http://127.0.0.1:8000') . '/api/v2/dgii-mock',
            'fc_base'        => env('APP_URL', 'http://127.0.0.1:8000') . '/api/v2/dgii-mock',
            'timbre_url'     => 'https://ecf.dgii.gov.do/TesteCF/ConsultaTimbre',
            'timbre_fc_url'  => 'https://fc.dgii.gov.do/TesteCF/ConsultaTimbreFC',
        ],
    ],
];

