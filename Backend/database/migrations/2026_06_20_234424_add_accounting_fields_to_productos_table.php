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
    public function up(): void
    {
        Schema::table('productos', function (Blueprint $table) {
            $table->foreignId('unidad_medida_id')->nullable()->after('descripcion');
            $table->foreignId('impuesto_venta_id')->nullable()->after('impuesto_id');
            $table->foreignId('impuesto_compra_id')->nullable()->after('impuesto_venta_id');
            $table->boolean('precio_incluye_impuesto')->default(false)->after('precio_venta');
            $table->boolean('maneja_vencimiento')->default(false)->after('maneja_inventario');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('productos', function (Blueprint $table) {
            $table->dropColumn([
                'unidad_medida_id',
                'impuesto_venta_id',
                'impuesto_compra_id',
                'precio_incluye_impuesto',
                'maneja_vencimiento'
            ]);
        });
    }
};
