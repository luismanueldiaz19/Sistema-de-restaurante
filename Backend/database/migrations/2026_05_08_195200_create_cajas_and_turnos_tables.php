<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up()
    {
        // 1. Catálogo de Cajas Físicas
        Schema::create('cajas', function (Blueprint $table) {
            $table->id();
            $table->string('nombre'); // Ej: Caja 1, POS Principal
            $table->boolean('activa')->default(true);
            $table->timestamps();
        });

        // 2. Catálogo de Turnos
        Schema::create('turnos', function (Blueprint $table) {
            $table->id();
            $table->string('nombre'); // Ej: Mañana, Tarde, Noche
            $table->time('hora_inicio');
            $table->time('hora_fin');
            $table->timestamps();
        });

        // 3. Sesiones de Caja (El corazón del módulo)
        Schema::create('caja_sesiones', function (Blueprint $table) {
            $table->id();
            $table->foreignId('caja_id')->constrained('cajas');
            $table->foreignId('user_id')->constrained('users'); // El cajero
            $table->foreignId('turno_id')->constrained('turnos');
            
            $table->decimal('monto_inicial', 15, 2)->default(0);
            $table->decimal('monto_final_esperado', 15, 2)->default(0); // Suma de ventas
            $table->decimal('monto_final_fisico', 15, 2)->nullable(); // Lo que contó el cajero
            $table->decimal('diferencia', 15, 2)->default(0); // Sobrante o Faltante
            
            $table->enum('estado', ['abierta', 'cerrada'])->default('abierta');
            $table->timestamp('fecha_apertura')->useCurrent();
            $table->timestamp('fecha_cierre')->nullable();
            
            $table->text('comentario')->nullable();
            $table->timestamps();
        });
    }

    public function down()
    {
        Schema::dropIfExists('caja_sesiones');
        Schema::dropIfExists('turnos');
        Schema::dropIfExists('cajas');
    }
};
