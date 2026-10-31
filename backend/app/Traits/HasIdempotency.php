<?php

namespace App\Traits;

use App\Models\IdempotencyRequest;
use Illuminate\Database\QueryException;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

/**
 * Trait HasIdempotency
 *
 * Agrega protección anti-duplicados a cualquier operación financiera.
 * Implementa el patrón de tabla dedicada (estilo Stripe):
 *
 *  1. checkIdempotency() — llamar ANTES del DB::beginTransaction().
 *     - Si el key+endpoint ya fue procesado (completed) → replay de respuesta cacheada.
 *     - Si está en proceso (processing) → 409 Conflict.
 *     - Si falló antes (failed) → permite reintento.
 *     - Si es nuevo → inserta registro 'processing' y retorna null (proceder).
 *
 *  2. saveIdempotency() — llamar DESPUÉS del DB::commit() al retornar la respuesta.
 *     Guarda la respuesta JSON y el HTTP status en la tabla para futuros replays.
 *
 *  3. failIdempotency() — llamar en el bloque catch, DESPUÉS del DB::rollBack().
 *     Marca el registro como 'failed' para permitir reintentos.
 *
 * Uso en un Controller:
 *
 *   use App\Traits\HasIdempotency;
 *
 *   class MiController extends Controller {
 *       use HasIdempotency;
 *
 *       public function store(Request $request) {
 *           $cached = $this->checkIdempotency($request, 'mi_operacion.store');
 *           if ($cached) return $cached;
 *
 *           DB::beginTransaction();
 *           try {
 *               // ... lógica ...
 *               DB::commit();
 *               return $this->saveIdempotency($request, 'mi_operacion.store', $data, 201);
 *           } catch (Exception $e) {
 *               DB::rollBack();
 *               $this->failIdempotency($request, 'mi_operacion.store');
 *               return response()->json(['error' => $e->getMessage()], 500);
 *           }
 *       }
 *   }
 */
trait HasIdempotency
{
    /**
     * Verifica si ya existe un request previo con el mismo key+endpoint.
     *
     * @param  Request $request
     * @param  string  $endpoint  Identificador único de la operación ('compra.store', etc.)
     * @return JsonResponse|null  null si se debe proceder; JsonResponse si se debe retornar.
     */
    protected function checkIdempotency(Request $request, string $endpoint): ?JsonResponse
    {
        $key = $request->input('idempotency_key');

        // Sin key → no aplica idempotencia, proceder normalmente
        if (empty($key)) {
            return null;
        }

        // Intentar insertar el registro en estado 'processing'.
        // Si ya existe (constraint unique key+endpoint), capturamos la excepción
        // y consultamos el estado del registro existente.
        try {
            IdempotencyRequest::create([
                'idempotency_key' => $key,
                'endpoint'        => $endpoint,
                'status'          => 'processing',
                'usuario_id'      => auth()->id(),
                'expires_at'      => now()->addHours(24),
            ]);

            // Inserción exitosa → es un request nuevo, proceder con la operación
            return null;

        } catch (QueryException $e) {
            // Violación de unique constraint → ya existe un registro para este key+endpoint
            // Consultar el estado actual del registro existente
            $existing = IdempotencyRequest::where('idempotency_key', $key)
                ->where('endpoint', $endpoint)
                ->vigente()
                ->first();

            if (!$existing) {
                // El key existía pero ya expiró → tratar como nuevo
                // Actualizar el registro expirado para reutilizarlo
                IdempotencyRequest::where('idempotency_key', $key)
                    ->where('endpoint', $endpoint)
                    ->update([
                        'status'     => 'processing',
                        'expires_at' => now()->addHours(24),
                        'response_body' => null,
                        'response_code' => null,
                    ]);
                return null;
            }

            return match ($existing->status) {
                // ✅ Completado → replay exacto de la respuesta cacheada
                'completed' => response()->json(
                    json_decode($existing->response_body, true),
                    $existing->response_code
                ),

                // ⏳ En proceso → otro request concurrente está ejecutando la operación
                'processing' => response()->json([
                    'message'         => 'Este request ya está siendo procesado. Intente nuevamente en unos segundos.',
                    'idempotency_key' => $key,
                ], 409),

                // ❌ Falló antes → permitir reintento actualizando a 'processing'
                'failed' => $this->retryIdempotency($key, $endpoint),

                default => null,
            };
        }
    }

    /**
     * Guarda la respuesta exitosa en la tabla y la devuelve al cliente.
     * Llamar DESPUÉS del DB::commit().
     *
     * @param  Request  $request
     * @param  string   $endpoint
     * @param  mixed    $data       Datos a serializar como JSON
     * @param  int      $httpCode   HTTP status code (201 para creación, 200 para pago)
     * @return JsonResponse
     */
    protected function saveIdempotency(
        Request $request,
        string $endpoint,
        mixed $data,
        int $httpCode = 201
    ): JsonResponse {
        $key = $request->input('idempotency_key');

        if (!empty($key)) {
            IdempotencyRequest::where('idempotency_key', $key)
                ->where('endpoint', $endpoint)
                ->update([
                    'status'        => 'completed',
                    'response_body' => json_encode($data),
                    'response_code' => $httpCode,
                ]);
        }

        return response()->json($data, $httpCode);
    }

    /**
     * Marca el request como fallido para permitir reintentos.
     * Llamar en el bloque catch, DESPUÉS del DB::rollBack().
     *
     * @param  Request $request
     * @param  string  $endpoint
     */
    protected function failIdempotency(Request $request, string $endpoint): void
    {
        $key = $request->input('idempotency_key');

        if (!empty($key)) {
            IdempotencyRequest::where('idempotency_key', $key)
                ->where('endpoint', $endpoint)
                ->update(['status' => 'failed']);
        }
    }

    /**
     * Actualiza un registro 'failed' a 'processing' para permitir el reintento.
     * Uso interno del trait.
     */
    private function retryIdempotency(string $key, string $endpoint): ?JsonResponse
    {
        IdempotencyRequest::where('idempotency_key', $key)
            ->where('endpoint', $endpoint)
            ->update([
                'status'        => 'processing',
                'response_body' => null,
                'response_code' => null,
                'expires_at'    => now()->addHours(24),
            ]);

        // null → proceder con la operación en el controller
        return null;
    }
}
