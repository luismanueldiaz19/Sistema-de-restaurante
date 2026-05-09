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
        Schema::create('productos', function (Blueprint $table) {
            $table->id();
            $table->string('nombre');
            $table->string('codigo')->unique()->nullable();
            $table->string('descripcion')->nullable();
            $table->string('categoria')->default('GENERAL');
            $table->string('unidad_medida')->default('UND'); // UND, KG, LB, etc.
            
            // Precios e Impuestos
            $table->decimal('precio_venta', 15, 2)->default(0);
            $table->decimal('costo', 15, 2)->default(0);
            $table->decimal('itbis_porcentaje', 5, 2)->default(18); // Por defecto 18% ITBIS
            
            // Inventario
            $table->boolean('maneja_inventario')->default(true);
            $table->decimal('stock_actual', 15, 2)->default(0);
            $table->decimal('stock_minimo', 15, 2)->default(0);
            
            // Configuración Contable
            $table->string('cuenta_contable_ingresos')->default('4.1.01'); // Ventas Alimentos por defecto
            $table->string('cuenta_contable_inventario')->default('1.1.05.01'); // Inventario Alimentos
            $table->string('cuenta_contable_costos')->default('5.1'); // Costo Alimentos
            $table->boolean('activo')->default(true);
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('productos');
    }
};
