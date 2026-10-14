<?php

declare(strict_types=1);

namespace App\Modules\Contabilidad\Services;

use App\Models\ConfiguracionContable;
use App\Models\CatalogoCuenta;
use App\Modules\Contabilidad\Exceptions\ContabilidadException;
use Illuminate\Database\Eloquent\Collection;
use Illuminate\Support\Facades\DB;

class ConfiguracionContableService
{
    /**
     * Obtener todas las configuraciones contables o filtradas por grupo (Ventas, Compras, Nomina, etc.).
     */
    public function obtenerConfiguraciones(?string $grupo = null): Collection
    {
        $query = ConfiguracionContable::with('cuenta');

        if ($grupo !== null && $grupo !== '') {
            $query->where('grupo', $grupo);
        }

        return $query->get();
    }

    /**
     * Obtener el mapa asociativo ['clave' => cuenta_id] para el motor de asientos contables.
     */
    public function obtenerMapaConfiguraciones(): array
    {
        return ConfiguracionContable::pluck('cuenta_id', 'clave')->toArray();
    }

    /**
     * Obtener el ID de la cuenta configurada para una clave específica.
     */
    public function obtenerCuentaPorClave(string $clave): ?int
    {
        $config = ConfiguracionContable::where('clave', $clave)->first();
        return $config?->cuenta_id;
    }

    /**
     * Actualizar una configuración contable individual con validaciones contables.
     */
    public function actualizar(int $id, ?int $cuentaId): ConfiguracionContable
    {
        $config = ConfiguracionContable::find($id);

        if (!$config) {
            throw new ContabilidadException("Configuración contable no encontrada con ID: {$id}.");
        }

        if ($cuentaId !== null) {
            $this->validarCuentaPermiteMovimiento($cuentaId);
        }

        $config->cuenta_id = $cuentaId;
        $config->save();

        return $config->load('cuenta');
    }

    /**
     * Actualizar múltiples configuraciones contables en lote dentro de una transacción.
     *
     * @param array<int, array{id: int, cuenta_id: int|null}> $configs
     * @return Collection
     */
    public function actualizarBulk(array $configs): Collection
    {
        return DB::transaction(function () use ($configs) {
            $updatedIds = [];

            foreach ($configs as $item) {
                $id = (int) ($item['id'] ?? 0);
                $cuentaId = isset($item['cuenta_id']) && $item['cuenta_id'] !== null ? (int) $item['cuenta_id'] : null;

                $config = ConfiguracionContable::find($id);
                if (!$config) {
                    continue;
                }

                if ($cuentaId !== null) {
                    $this->validarCuentaPermiteMovimiento($cuentaId);
                }

                $config->cuenta_id = $cuentaId;
                $config->save();
                $updatedIds[] = $config->id;
            }

            return ConfiguracionContable::with('cuenta')
                ->whereIn('id', $updatedIds)
                ->get();
        });
    }

    /**
     * Valida que las claves requeridas para una operación contable estén configuradas.
     *
     * @param array<string, string> $clavesRequeridas Array de ['clave' => 'Nombre descriptivo de la operación']
     * @throws ContabilidadException
     */
    public function validarClavesConfiguradas(array $clavesRequeridas, ?array $mapaActual = null): void
    {
        $mapa = $mapaActual ?? $this->obtenerMapaConfiguraciones();

        foreach ($clavesRequeridas as $clave => $nombreDescriptivo) {
            if (empty($mapa[$clave])) {
                throw new ContabilidadException(
                    "Falta configurar la cuenta contable para: '{$nombreDescriptivo}' (Clave: {$clave}). Por favor asígnela en Configuración Contable Automática."
                );
            }
        }
    }

    /**
     * Valida que una cuenta contable exista y sea de detalle (permite movimiento).
     */
    protected function validarCuentaPermiteMovimiento(int $cuentaId): CatalogoCuenta
    {
        $cuenta = CatalogoCuenta::find($cuentaId);

        if (!$cuenta) {
            throw new ContabilidadException("La cuenta contable con ID {$cuentaId} no existe en el catálogo.");
        }

        if (!$cuenta->permite_movimiento) {
            throw new ContabilidadException(
                "La cuenta contable '{$cuenta->codigo} - {$cuenta->nombre}' es una cuenta de grupo/acumulación. Debe seleccionar una cuenta de detalle que permita movimientos."
            );
        }

        return $cuenta;
    }
}
