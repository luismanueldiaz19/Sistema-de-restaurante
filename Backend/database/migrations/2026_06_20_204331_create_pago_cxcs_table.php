<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('pagos_cxc', function (Blueprint $table) {
            $table->id();
            $table->foreignId('cxc_id')->constrained('cuentas_por_cobrar')->onDelete('cascade');
            $table->decimal('monto_pagado', 12, 2);
            $table->date('fecha_pago');
            $table->string('metodo_pago', 50)->default('EFECTIVO');
            $table->string('referencia')->nullable();
            $table->foreignId('cuenta_destino_id')->nullable()->constrained('catalogo_cuentas')->onDelete('set null'); // Banco o Caja
            $table->foreignId('usuario_id')->nullable()->constrained('users')->onDelete('set null');
            $table->foreignId('asiento_id')->nullable()->constrained('asientos_contables')->onDelete('set null');
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('pagos_cxc');
    }
};
