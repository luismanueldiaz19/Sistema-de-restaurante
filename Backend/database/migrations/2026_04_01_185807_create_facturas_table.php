<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class () extends Migration {
    /**
     * Run the migrations.
     */
    public function up()
    {
        Schema::create('facturas', function (Blueprint $table) {
           $table->id();
           // 🔗 Relación
           $table->foreignId('cliente_id')->constrained()->cascadeOnDelete();
           $table->foreignId('user_id')->nullable()->constrained('users');
           $table->foreignId('caja_sesion_id')->nullable()->constrained('caja_sesiones');
           
           // 📄 Datos fiscales
          $table->string('ncf')->unique();
          $table->string('tipo_factura')->default('consumo_final');
          $table->integer('dias_credito')->default(0);

          // 📅 Fechas
          $table->date('fecha_emision');
          $table->date('fecha_vencimiento')->nullable();

          // 💰 Totales
           $table->decimal('subtotal', 12, 2)->default(0);
           $table->decimal('descuento_total', 12, 2)->default(0);
           $table->decimal('itbis', 12, 2)->default(0);
           $table->decimal('total', 12, 2)->default(0);
           
           $table->text('nota')->nullable();

           // 🧾 Estado
           $table->enum('estado', ['pendiente', 'pagada', 'anulada'])->default('pendiente');

           $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down()
    {
        Schema::dropIfExists('facturas');
    }
};
