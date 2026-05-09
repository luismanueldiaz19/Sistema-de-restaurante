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
        Schema::create('catalogo_cuentas', function (Blueprint $table) {
            $table->id();
            $table->string('codigo')->unique(); // Ej: 1101-01
            $table->string('nombre');
            $table->enum('tipo', ['Activo', 'Pasivo', 'Capital', 'Ingresos', 'Costos', 'Gastos']);
            $table->integer('nivel')->default(1); // 1: Grupo, 2: Control, 3: Detalle
            $table->unsignedBigInteger('padre_id')->nullable();
            $table->boolean('permite_movimiento')->default(false); // Solo las de detalle permiten transacciones
            $table->timestamps();

            $table->foreign('padre_id')->references('id')->on('catalogo_cuentas')->onDelete('cascade');
        });
    }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down()
    {
        Schema::dropIfExists('catalogo_cuentas');
    }
};
