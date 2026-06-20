<?php

namespace App\Services;

use App\Models\AsientoContable;
use App\Models\AsientoDetalle;
use App\Models\ConfiguracionContable;
use App\Accounting\AsientoStrategyFactory;
use Illuminate\Support\Facades\DB;
use Exception;

class ContabilidadService
{
    /**
     * Registrar un asiento contable automático basado en las configuraciones contables activas.
     *
     * @param  string  $tipoTransaccion  ('venta_efectivo', 'venta_credito', 'compra_inventario', 'pago_nomina')
     * @param  float   $subtotal
     * @param  float   $itbis
     * @param  float   $total
     * @param  string  $referencia
     * @param  string  $glosa
     * @param  int|null $usuarioId
     * @return AsientoContable|null
     * @throws Exception
     */
    public function registrarAsientoAuto(
        string $tipoTransaccion,
        float $subtotal,
        float $itbis,
        float $total,
        string $referencia,
        string $glosa,
        int $usuarioId = null,
        array $customConfigs = []
    ) {
        if ($total <= 0) {
            return null;
        }

        return DB::transaction(function () use ($tipoTransaccion, $subtotal, $itbis, $total, $referencia, $glosa, $usuarioId, $customConfigs) {
            // 1. Cargar las configuraciones contables para obtener las cuentas correspondientes
            $configs = ConfiguracionContable::pluck('cuenta_id', 'clave')->toArray();
            if (!empty($customConfigs)) {
                $configs = array_merge($configs, $customConfigs);
            }

            // 2. Obtener la estrategia contable adecuada mediante el Factory (Patrón Estrategia)
            $strategy = AsientoStrategyFactory::make($tipoTransaccion);
            
            // 3. Generar las líneas de débito y crédito del asiento de forma dinámica
            $detalles = $strategy->generarDetalles($configs, $subtotal, $itbis, $total);

            // 4. Crear la cabecera del asiento contable (Journal Entry Header)
            $asiento = AsientoContable::create([
                'fecha' => now()->toDateString(),
                'glosa' => $glosa,
                'referencia' => $referencia,
                'usuario_id' => $usuarioId,
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
                throw new Exception("Inconsistencia contable: El asiento no cuadra (Débito: $totalDebito, Crédito: $totalCredito).");
            }

            return $asiento->load('detalles.cuenta');
        });
    }
}
