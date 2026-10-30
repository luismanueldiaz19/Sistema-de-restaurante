<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('ecf_configuraciones', function (Blueprint $table) {
            $table->id();
            $table->string('ambiente', 20)->default('mock'); // mock, TesteCF, CerteCF, eCF
            $table->string('rnc_emisor', 15);
            $table->string('razon_social', 150);
            $table->string('nombre_comercial', 150)->nullable();
            $table->string('direccion', 250);
            $table->string('municipio', 10)->nullable();
            $table->string('provincia', 10)->nullable();
            $table->string('telefono', 25)->nullable();
            $table->string('correo', 120)->nullable();
            $table->string('sitio_web', 150)->nullable();
            $table->string('certificado_path', 300)->nullable();
            $table->text('certificado_password')->nullable(); // Cifrado con Crypt
            $table->boolean('envio_automatico')->default(true);
            $table->boolean('activo')->default(true);
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('ecf_configuraciones');
    }
};

