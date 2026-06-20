<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up(): void
    {
        Schema::create('pagos_dgii', function (Blueprint $table) {
            $table->id();
            $table->date('fecha_pago');
            $table->decimal('monto_pagado', 12, 2);
            $table->string('periodo_mes', 2);
            $table->string('periodo_anio', 4);
            $table->string('referencia')->nullable();
            
            // Relaciones
            $table->foreignId('cuenta_origen_id')->constrained('catalogo_cuentas');
            $table->foreignId('usuario_id')->constrained('users');
            $table->foreignId('asiento_id')->nullable()->constrained('asientos_contables');
            
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('pagos_dgii');
    }
};
