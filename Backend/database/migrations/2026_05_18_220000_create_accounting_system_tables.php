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
    public function up()
    {
        // 1. Configuraciones Contables
        Schema::create('configuraciones_contables', function (Blueprint $table) {
            $table->id();
            $table->string('clave')->unique(); // Ej: 'venta_efectivo_debe'
            $table->string('nombre');          // Ej: 'Caja para Ventas en Efectivo'
            $table->string('grupo');           // Ej: 'Ventas', 'Compras', 'Nomina'
            $table->unsignedBigInteger('cuenta_id')->nullable();
            $table->timestamps();

            $table->foreign('cuenta_id')->references('id')->on('catalogo_cuentas')->onDelete('set null');
        });

        // 2. Asientos Contables
        Schema::create('asientos_contables', function (Blueprint $table) {
            $table->id();
            $table->date('fecha');
            $table->text('glosa')->nullable();
            $table->string('referencia')->nullable();
            $table->unsignedBigInteger('usuario_id')->nullable();
            $table->enum('estado', ['Borrador', 'Posteado', 'Anulado'])->default('Posteado');
            $table->timestamps();

            $table->foreign('usuario_id')->references('id')->on('users')->onDelete('set null');
        });

        // 3. Detalles de Asiento
        Schema::create('asiento_detalles', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('asiento_id');
            $table->unsignedBigInteger('cuenta_id');
            $table->decimal('debito', 15, 2)->default(0.00);
            $table->decimal('credito', 15, 2)->default(0.00);
            $table->timestamps();

            $table->foreign('asiento_id')->references('id')->on('asientos_contables')->onDelete('cascade');
            $table->foreign('cuenta_id')->references('id')->on('catalogo_cuentas')->onDelete('cascade');
        });
    }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down()
    {
        Schema::dropIfExists('asiento_detalles');
        Schema::dropIfExists('asientos_contables');
        Schema::dropIfExists('configuraciones_contables');
    }
};
