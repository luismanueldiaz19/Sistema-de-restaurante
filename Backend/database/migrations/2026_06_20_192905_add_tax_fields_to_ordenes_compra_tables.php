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
        Schema::table('ordenes_compra', function (Blueprint $table) {
            $table->date('fecha_vencimiento')->nullable()->after('fecha');
            $table->decimal('subtotal', 12, 2)->default(0)->after('fecha_vencimiento');
            $table->decimal('descuento_total', 12, 2)->default(0)->after('subtotal');
            $table->decimal('itbis', 12, 2)->default(0)->after('descuento_total');
        });

        Schema::table('orden_compra_detalles', function (Blueprint $table) {
            // Renombrar costo_esperado a precio para que sea consistente con Cotizacion y Factura
            // Pero como sqlite puede tener problemas con renombrar, o si es mysql, probaremos
            // Mejor añadimos los campos faltantes
            $table->decimal('itbis', 10, 2)->default(0)->after('costo_esperado');
            // La columna 'subtotal' ya existe, añadimos 'total'
            $table->decimal('total', 10, 2)->default(0)->after('subtotal');
        });
    }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down()
    {
        Schema::table('orden_compra_detalles', function (Blueprint $table) {
            $table->dropColumn(['itbis', 'total']);
        });

        Schema::table('ordenes_compra', function (Blueprint $table) {
            $table->dropColumn(['fecha_vencimiento', 'subtotal', 'descuento_total', 'itbis']);
        });
    }
};
