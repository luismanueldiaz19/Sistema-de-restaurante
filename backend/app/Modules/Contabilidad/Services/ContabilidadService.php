<?php
declare(strict_types=1);

namespace App\Modules\Contabilidad\Services;

use App\Models\AsientoContable;
use App\Models\AsientoDetalle;
use App\Models\ConfiguracionContable;
use App\Accounting\AsientoStrategyFactory;
use App\Modules\Contabilidad\Exceptions\ContabilidadException;
use Illuminate\Support\Facades\DB;

class ContabilidadService
{
    public function registrarAsientoAuto(\App\Modules\Contabilidad\DTOs\RegistrarAsientoDTO $dto) {
        if ($dto->total <= 0) {
            return null;
        }

        return DB::transaction(function () use ($dto) {
            // 1. Cargar las configuraciones contables para obtener las cuentas correspondientes
            $configs = ConfiguracionContable::pluck('cuenta_id', 'clave')->toArray();
            if (!empty($dto->custom_configs)) {
                $configs = array_merge($configs, $dto->custom_configs);
            }

            // 2. Obtener la estrategia contable adecuada mediante el Factory (Patrón Estrategia)
            $strategy = AsientoStrategyFactory::make($dto->tipo_transaccion);
            
            // 3. Generar las líneas de débito y crédito del asiento de forma dinámica
            $detalles = $strategy->generarDetalles($configs, $dto->subtotal, $dto->itbis, $dto->total, $dto->costo);

            // 4. Crear la cabecera del asiento contable (Journal Entry Header)
            $asiento = AsientoContable::create([
                'fecha' => now()->toDateString(),
                'glosa' => $dto->glosa,
                'referencia' => $dto->referencia,
                'usuario_id' => $dto->usuario_id,
                'estado' => 'Posteado'
            ]);

            // 5. Crear los detalles del asiento
            $totalDebito = 0.00;
            $totalCredito = 0.00;

            foreach ($detalles as $det) {
                AsientoDetalle::create([
                    'asiento_id' => $asiento->id,
                    'cuenta_id' => $det['cuenta_id'],
                    'debito' => $det['debito'],
                    'credito' => $det['credito']
                ]);
                $totalDebito += $det['debito'];
                $totalCredito += $det['credito'];
            }

            // 6. Validar que la partida doble cuadre perfectamente (Double Entry checking)
            if (abs($totalDebito - $totalCredito) > 0.05) {
                throw new ContabilidadException("Inconsistencia contable: El asiento no cuadra (Débito: $totalDebito, Crédito: $totalCredito).");
            }

            return $asiento->load('detalles.cuenta');
        });
    }

    /**
     * Registra un asiento contable de forma manual (ej. por un contador).
     */
    public function registrarAsientoManual(array $datosAsiento, array $detalles, int $usuarioId = null)
    {
        return DB::transaction(function () use ($datosAsiento, $detalles, $usuarioId) {
            $totalDebito = 0.00;
            $totalCredito = 0.00;

            // 1. Validar partida doble antes de crear el registro
            foreach ($detalles as $det) {
                $totalDebito += (float) ($det['debito'] ?? 0);
                $totalCredito += (float) ($det['credito'] ?? 0);
            }

            if (abs($totalDebito - $totalCredito) > 0.05) {
                throw new ContabilidadException("Inconsistencia contable: El asiento manual no cuadra (Débito: $totalDebito, Crédito: $totalCredito).");
            }

            // 2. Crear cabecera
            $asiento = AsientoContable::create([
                'fecha' => $datosAsiento['fecha'] ?? now()->toDateString(),
                'glosa' => $datosAsiento['glosa'] ?? 'Asiento manual',
                'referencia' => $datosAsiento['referencia'] ?? null,
                'usuario_id' => $usuarioId,
                'estado' => 'Posteado'
            ]);

            // 3. Crear detalles
            foreach ($detalles as $det) {
                AsientoDetalle::create([
                    'asiento_id' => $asiento->id,
                    'cuenta_id' => $det['cuenta_id'],
                    'debito' => $det['debito'] ?? 0.00,
                    'credito' => $det['credito'] ?? 0.00
                ]);
            }

            return $asiento->load('detalles.cuenta');
        });
    }
}
