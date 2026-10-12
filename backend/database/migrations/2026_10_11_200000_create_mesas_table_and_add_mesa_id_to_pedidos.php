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
        // 1. Crear tabla de mesas
        Schema::create('mesas', function (Blueprint $table) {
            $table->id();
            $table->string('nombre', 50);
            $table->string('area', 50)->default('Principal');
            $table->integer('capacidad')->default(4);
            $table->enum('estado', ['Libre', 'Ocupada', 'PorCobrar', 'Inactiva'])->default('Libre');
            $table->unsignedBigInteger('orden_activa_id')->nullable();
            $table->timestamps();
        });

        // 2. Agregar mesa_id a la tabla pedidos
        Schema::table('pedidos', function (Blueprint $table) {
            $table->unsignedBigInteger('mesa_id')->nullable()->after('factura_id');
            $table->foreign('mesa_id')->references('id')->on('mesas')->onDelete('set null');
        });

        // 3. Foreign key de orden_activa_id en mesas apuntando a pedidos
        Schema::table('mesas', function (Blueprint $table) {
            $table->foreign('orden_activa_id')->references('id')->on('pedidos')->onDelete('set null');
        });
    }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down()
    {
        Schema::table('mesas', function (Blueprint $table) {
            $table->dropForeign(['orden_activa_id']);
        });

        Schema::table('pedidos', function (Blueprint $table) {
            $table->dropForeign(['mesa_id']);
            $table->dropColumn('mesa_id');
        });

        Schema::dropIfExists('mesas');
    }
};
