<?php

namespace App\Modules\Ecf\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Facades\Crypt;
use Illuminate\Support\Facades\Schema;

class EcfConfiguracion extends Model
{
    protected $table = 'ecf_configuraciones';

    protected $fillable = [
        'ambiente',
        'rnc_emisor',
        'razon_social',
        'nombre_comercial',
        'direccion',
        'municipio',
        'provincia',
        'telefono',
        'correo',
        'sitio_web',
        'certificado_path',
        'certificado_password',
        'envio_automatico',
        'activo',
    ];

    protected $casts = [
        'envio_automatico' => 'boolean',
        'activo'           => 'boolean',
    ];

    protected $hidden = [
        'certificado_password',
    ];

    /**
     * Devuelve el RNC limpio (solo dígitos, 9 u 11 caracteres).
     */
    public function getRncLimpioAttribute(): string
    {
        return preg_replace('/[^0-9]/', '', (string) $this->rnc_emisor);
    }

    /**
     * Guarda la contraseña del certificado cifrada en base de datos.
     */
    public function setPasswordPlain(?string $plainPassword): void
    {
        if ($plainPassword === null || $plainPassword === '') {
            return;
        }
        $this->certificado_password = Crypt::encryptString($plainPassword);
    }

    /**
     * Obtiene la contraseña desencriptada del certificado.
     */
    public function getPasswordPlain(): string
    {
        if (empty($this->certificado_password)) {
            return (string) config('ecf.certificado.password', '1234');
        }

        try {
            return Crypt::decryptString($this->certificado_password);
        } catch (\Throwable $e) {
            return (string) $this->certificado_password;
        }
    }

    /**
     * Obtiene la ruta efectiva al archivo .p12.
     */
    public function getEffectiveCertPath(): string
    {
        if (!empty($this->certificado_path)) {
            return $this->certificado_path;
        }

        return (string) config('ecf.certificado.path', storage_path('app/dgii/certs/certificado_prueba.p12'));
    }

    /**
     * Obtiene (o inicializa desde config/ecf.php) la configuración activa del emisor.
     */
    public static function obtenerActiva(): self
    {
        if (Schema::hasTable('ecf_configuraciones')) {
            $config = self::where('activo', true)->latest('id')->first();
            if ($config) {
                return $config;
            }

            $created = new self([
                'ambiente'         => config('ecf.ambiente', 'mock'),
                'rnc_emisor'       => preg_replace('/[^0-9]/', '', (string) config('ecf.emisor.rnc', '40224129524')),
                'razon_social'     => config('ecf.emisor.razon_social', 'MENUXA RESTAURANTE SRL'),
                'nombre_comercial' => config('ecf.emisor.nombre_comercial', 'MENUXA'),
                'direccion'        => config('ecf.emisor.direccion', 'Av. Juan Pablo Duarte, Santiago'),
                'municipio'        => config('ecf.emisor.municipio', '250100'),
                'provincia'        => config('ecf.emisor.provincia', '250000'),
                'telefono'         => config('ecf.emisor.telefono', '809-769-9580'),
                'correo'           => config('ecf.emisor.correo', 'facturacion@menuxa.com'),
                'sitio_web'        => config('ecf.emisor.web', 'www.menuxa.com'),
                'certificado_path' => config('ecf.certificado.path', storage_path('app/dgii/certs/certificado_prueba.p12')),
                'envio_automatico' => true,
                'activo'           => true,
            ]);
            $created->setPasswordPlain((string) config('ecf.certificado.password', '1234'));
            $created->save();

            return $created;
        }

        $fallback = new self([
            'ambiente'         => config('ecf.ambiente', 'mock'),
            'rnc_emisor'       => preg_replace('/[^0-9]/', '', (string) config('ecf.emisor.rnc', '40224129524')),
            'razon_social'     => config('ecf.emisor.razon_social', 'MENUXA RESTAURANTE SRL'),
            'nombre_comercial' => config('ecf.emisor.nombre_comercial', 'MENUXA'),
            'direccion'        => config('ecf.emisor.direccion', 'Av. Juan Pablo Duarte, Santiago'),
            'municipio'        => config('ecf.emisor.municipio', '250100'),
            'provincia'        => config('ecf.emisor.provincia', '250000'),
            'telefono'         => config('ecf.emisor.telefono', '809-769-9580'),
            'correo'           => config('ecf.emisor.correo', 'facturacion@menuxa.com'),
            'sitio_web'        => config('ecf.emisor.web', 'www.menuxa.com'),
            'certificado_path' => config('ecf.certificado.path', storage_path('app/dgii/certs/certificado_prueba.p12')),
            'envio_automatico' => true,
            'activo'           => true,
        ]);

        return $fallback;
    }
}
