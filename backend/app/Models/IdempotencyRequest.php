<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

/**
 * Modelo para la tabla `idempotency_requests`.
 *
 * Registra cada operación financiera crítica con su UUID del cliente,
 * el endpoint procesado, el estado y la respuesta cacheada.
 * Permite al backend detectar y rechazar duplicados sin re-ejecutar
 * ninguna transacción contable.
 */
class IdempotencyRequest extends Model
{
    protected $table = 'idempotency_requests';

    protected $fillable = [
        'idempotency_key',
        'endpoint',
        'status',
        'response_body',
        'response_code',
        'usuario_id',
        'expires_at',
    ];

    protected $casts = [
        'expires_at' => 'datetime',
    ];

    public function usuario()
    {
        return $this->belongsTo(User::class, 'usuario_id');
    }

    /**
     * Scope: solo registros vigentes (no expirados).
     */
    public function scopeVigente($query)
    {
        return $query->where('expires_at', '>', now());
    }
}
