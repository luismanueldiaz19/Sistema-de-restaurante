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
        Schema::create('pagos', function (Blueprint $table) {
            $table->id();
            $table->foreignId('factura_id')->constrained('facturas')->onDelete('cascade');
            $table->foreignId('user_id')->constrained('users');
            $table->foreignId('caja_sesion_id')->nullable()->constrained('caja_sesiones');
            
            $table->decimal('monto_pagado', 12, 2); // Lo que se aplica a la deuda
            $table->decimal('monto_recibido', 12, 2); // Lo que entregó el cliente
            $table->decimal('devuelta', 12, 2)->default(0); // El cambio entregado
            
            $table->string('metodo_pago')->default('efectivo'); // efectivo, tarjeta, transferencia
            $table->foreignId('metodo_pago_id')->nullable()->constrained('metodo_pagos')->nullOnDelete();
            $table->string('referencia_pago')->nullable(); // Num tarjeta o transaccion
            
            $table->date('fecha_pago');
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
        Schema::dropIfExists('pagos');
    }
};
