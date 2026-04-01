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

            $table->foreignId('cliente_id')->constrained()->onDelete('cascade');

            $table->string('numero_factura')->nullable();
            $table->date('fecha');

            $table->decimal('subtotal', 10, 2)->default(0);
            $table->decimal('itbis', 10, 2)->default(0);
            $table->decimal('total', 10, 2)->default(0);

            $table->string('estado')->default('pendiente'); // pendiente, pagada

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
