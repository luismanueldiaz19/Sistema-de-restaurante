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

            // GENERAL
            $table->string('nombre');
            $table->string('codigo')->unique()->nullable();
            $table->text('descripcion')->nullable();

            // RELACIONES
            $table->foreignId('categoria_id')->nullable();
            $table->foreignId('marca_id')->nullable();
            $table->foreignId('unidad_medida_id')->nullable();

            // TIPOS
            $table->enum('tipo_producto', [
                'PRODUCTO',
                'SERVICIO',
                'COMBO',
                'MATERIA_PRIMA',
                'PLATO'
            ]);

            $table->enum('tipo_contable', [
                'INVENTARIO',
                'GASTO',
                'ACTIVO_FIJO',
                'SERVICIO'
            ]);

            // INVENTARIO
            $table->boolean('maneja_inventario')->default(true);
            $table->boolean('maneja_vencimiento')->default(false);
            $table->decimal('stock_actual', 15, 2)->default(0);
            $table->decimal('stock_minimo', 15, 2)->default(0);

            // PRECIOS
            $table->decimal('precio_venta', 15, 2)->default(0);
            $table->decimal('costo', 15, 2)->default(0);

            // IMPUESTOS
            $table->foreignId('impuesto_id')->nullable();
            $table->foreignId('impuesto_venta_id')->nullable();
            $table->foreignId('impuesto_compra_id')->nullable();

            // CONTABILIDAD
            $table->foreignId('cuenta_ingreso_id')->nullable();
            $table->foreignId('cuenta_inventario_id')->nullable();
            $table->foreignId('cuenta_costo_id')->nullable();
            $table->foreignId('cuenta_gasto_id')->nullable();

            // ESTADO
            $table->boolean('activo')->default(true);

            // AUDITORÍA
            $table->foreignId('created_by')->nullable();

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
