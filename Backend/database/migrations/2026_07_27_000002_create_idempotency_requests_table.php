<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Tabla Central de Idempotencia Financiera.
 *
 * Protege TODAS las operaciones financieras críticas del sistema contra
 * duplicados causados por fallos de red, timeouts o doble envío:
 *   - compra.store    → Registro de compras (contado y crédito)
 *   - cxp.pago        → Pagos a Cuentas por Pagar
 *   - factura.store   → Emisión de facturas (ventas)
 *   - nomina.store    → Creación de nóminas
 *   - cxc.pago        → Cobros de Cuentas por Cobrar
 *
 * El cliente Flutter genera un UUID v4 por formulario y lo envía en cada
 * reintento. El backend usa esta tabla para responder con la respuesta
 * cacheada sin re-ejecutar ninguna transacción contable.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('idempotency_requests', function (Blueprint $table) {
            $table->id();

            // UUID v4 generado por el cliente Flutter una sola vez por formulario
            $table->string('idempotency_key', 36)->index();

            // Identifica la operación financiera específica
            // Valores: 'compra.store' | 'cxp.pago' | 'factura.store' | 'nomina.store' | 'cxc.pago'
            $table->string('endpoint', 100);

            // Estado del procesamiento para manejar concurrencia simultánea
            $table->enum('status', ['processing', 'completed', 'failed'])
                  ->default('processing');

            // Respuesta cacheada — se devuelve tal cual en reintentos exitosos
            $table->longText('response_body')->nullable();
            $table->smallInteger('response_code')->nullable();

            // Usuario que realizó la operación
            $table->foreignId('usuario_id')
                  ->nullable()
                  ->constrained('users')
                  ->nullOnDelete();

            // TTL: el key expira en 24h — pasado ese tiempo se trata como nuevo request
            $table->timestamp('expires_at');

            $table->timestamps();

            // Índice único: un key solo puede existir UNA VEZ por endpoint.
            // Previene inserciones duplicadas en requests concurrentes (race condition).
            $table->unique(['idempotency_key', 'endpoint'], 'unq_idem_key_endpoint');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('idempotency_requests');
    }
};
