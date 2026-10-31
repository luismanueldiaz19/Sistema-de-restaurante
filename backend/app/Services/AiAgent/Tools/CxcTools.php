<?php

namespace App\Services\AiAgent\Tools;

use App\Models\Cliente;
use App\Models\CuentaPorCobrar;

class CxcTools
{
    /**
     * Define la estructura de las herramientas para enviárselas a Gemini.
     */
    public static function getToolDefinitions()
    {
        return [
            [
                'type' => 'function',
                'function' => [
                    'name' => 'consultar_deuda_cliente',
                    'description' => 'Busca a un cliente por su nombre y devuelve el balance total que debe actualmente.',
                    'parameters' => [
                        'type' => 'object',
                        'properties' => [
                            'nombre_cliente' => [
                                'type' => 'string',
                                'description' => 'El nombre del cliente a buscar (ej. Juan Perez, Maria)'
                            ]
                        ],
                        'required' => ['nombre_cliente']
                    ]
                ]
            ]
        ];
    }

    /**
     * Ejecuta la herramienta de consultar deuda.
     */
    public static function consultarDeudaCliente($nombreCliente)
    {
        $cliente = Cliente::where('nombre', 'like', '%' . $nombreCliente . '%')->first();

        if (!$cliente) {
            return [
                'status' => 'error',
                'message' => 'No se encontró ningún cliente con el nombre: ' . $nombreCliente
            ];
        }

        // Sumar las cuentas por cobrar pendientes.
        $deudaTotal = CuentaPorCobrar::where('cliente_id', $cliente->id)
            ->where('balance_pendiente', '>', 0)
            ->sum('balance_pendiente');

        return [
            'status' => 'success',
            'cliente' => $cliente->nombre,
            'rnc_cedula' => $cliente->rnc_cedula,
            'deuda_total' => $deudaTotal,
            'moneda' => 'RD$'
        ];
    }
}
