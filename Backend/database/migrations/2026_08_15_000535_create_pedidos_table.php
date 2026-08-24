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
        Schema::create('pedidos', function (Blueprint $table) {
            $table->id();
            $table->integer('secuencia_diaria');
            $table->string('codigo_barras')->nullable()->unique();
            $table->date('fecha');
            $table->string('cliente_nombre');
            $table->string('cliente_telefono');
            $table->text('direccion')->nullable();
            $table->enum('tipo_entrega', ['Domicilio', 'Recoger', 'Local'])->default('Recoger');
            $table->enum('estado', ['Pendiente', 'Confirmado', 'Preparando', 'Facturado', 'Cancelado'])->default('Pendiente');
            $table->decimal('total', 12, 2)->default(0);
            $table->text('nota')->nullable();
            $table->unsignedBigInteger('factura_id')->nullable();
            $table->foreign('factura_id')->references('id')->on('facturas')->onDelete('set null');
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
        Schema::dropIfExists('pedidos');
    }
};
