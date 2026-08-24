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
        Schema::create('metodo_pagos', function (Blueprint $table) {
            $table->id();
            $table->string('nombre'); // Ej: Efectivo, Tarjeta, Transferencia BHD
            $table->enum('tipo', ['efectivo', 'tarjeta', 'transferencia']);
            $table->foreignId('catalogo_cuenta_id')->nullable()->constrained('catalogo_cuentas');
            $table->boolean('activo')->default(true);
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down()
    {
        Schema::dropIfExists('metodo_pagos');
    }
};
