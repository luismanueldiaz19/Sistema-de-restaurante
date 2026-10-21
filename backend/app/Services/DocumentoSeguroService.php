<?php

declare(strict_types=1);

namespace App\Services;

use Illuminate\Support\Facades\Crypt;
use Exception;

class DocumentoSeguroService
{
    /**
     * Genera una URL temporal encriptada para visualizar documentos sin exponer credenciales.
     *
     * @param string $tipo Tipo de documento ('nota_credito', 'factura', 'cotizacion', etc.)
     * @param int $id ID del documento
     * @param int $minutosExpiracion Tiempo de validez en minutos (default: 15)
     * @return string URL pública temporal y segura
     */
    public static function generarUrlTemporal(string $tipo, int $id, int $minutosExpiracion = 15): string
    {
        $token = self::generarToken($tipo, $id, $minutosExpiracion);
        return url("/api/documentos/ver/{$token}");
    }

    /**
     * Genera un token encriptado URL-safe.
     */
    public static function generarToken(string $tipo, int $id, int $minutosExpiracion = 15): string
    {
        $payload = [
            'tipo'    => $tipo,
            'id'      => $id,
            'user_id' => auth()->id(),
            'exp'     => now()->addMinutes($minutosExpiracion)->timestamp,
            'nonce'   => bin2hex(random_bytes(6)),
        ];

        $json = json_encode($payload, JSON_THROW_ON_ERROR);
        $cifrado = Crypt::encryptString($json);

        // Convertir a base64 URL-safe (reemplazando +, / y eliminando padding =)
        return str_replace(['+', '/', '='], ['-', '_', ''], base64_encode($cifrado));
    }

    /**
     * Valida y desencripta el token temporal.
     *
     * @param string $token
     * @return array
     * @throws Exception Si el token es inválido o ha expirado.
     */
    public static function validarYObtenerDatos(string $token): array
    {
        try {
            // Recomponer padding base64
            $base64 = str_replace(['-', '_'], ['+', '/'], $token);
            $padding = strlen($base64) % 4;
            if ($padding > 0) {
                $base64 .= str_repeat('=', 4 - $padding);
            }

            $cifrado = base64_decode($base64, true);
            if ($cifrado === false) {
                throw new Exception('Token malformado.');
            }

            $json = Crypt::decryptString($cifrado);
            $data = json_decode($json, true, 512, JSON_THROW_ON_ERROR);

            if (!isset($data['exp']) || now()->timestamp > $data['exp']) {
                throw new Exception('El enlace temporal ha expirado.');
            }

            if (!isset($data['tipo']) || !isset($data['id'])) {
                throw new Exception('Parámetros de documento incompletos.');
            }

            return $data;
        } catch (Exception $e) {
            throw new Exception("Enlace de documento no válido o expirado: " . $e->getMessage());
        }
    }
}
