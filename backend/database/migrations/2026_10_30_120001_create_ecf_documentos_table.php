<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('ecf_documentos', function (Blueprint $table) {
            $table->id();
            $table->foreignId('factura_id')->nullable()->constrained('facturas')->nullOnDelete();
            $table->foreignId('nota_credito_id')->nullable()->constrained('notas_credito')->nullOnDelete();

            $table->string('encf', 15)->unique();
            $table->string('tipo_ecf', 4); // 31, 32, 33, 34, 44, 45, 46
            $table->boolean('es_resumen_fc')->default(false); // true para E32 < RD$250,000 (RFCE)

            $table->string('rnc_emisor', 15);
            $table->string('rnc_comprador', 20)->nullable();
            $table->string('razon_social_comprador', 150)->nullable();

            $table->decimal('monto_gravado', 14, 2)->default(0);
            $table->decimal('monto_exento', 14, 2)->default(0);
            $table->decimal('total_itbis', 14, 2)->default(0);
            $table->decimal('monto_total', 14, 2)->default(0);

            $table->string('codigo_seguridad', 10); // Primeros 6 caracteres de SignatureValue
            $table->date('fecha_emision');
            $table->string('fecha_hora_firma', 25); // dd-MM-yyyy HH:mm:ss
            $table->text('qr_url');

            $table->string('xml_path', 300)->nullable();
            $table->longText('xml_firmado');
            $table->longText('xml_rfce_firmado')->nullable();

            $table->boolean('xsd_valido')->default(false);
            $table->json('xsd_errores')->nullable();

            $table->string('ambiente', 20)->default('mock');
            $table->string('track_id', 100)->nullable()->index();
            $table->string('estado_dgii', 35)->default('PENDIENTE')->index();
            $table->json('respuesta_dgii')->nullable();
            $table->timestamp('fecha_envio')->nullable();
            $table->unsignedInteger('intentos_envio')->default(0);
            $table->text('ultimo_error')->nullable();

            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('ecf_documentos');
    }
};

