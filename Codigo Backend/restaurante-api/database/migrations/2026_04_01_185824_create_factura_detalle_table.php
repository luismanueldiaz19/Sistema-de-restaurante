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
    public function up() {
        Schema::create('factura_detalle', function (Blueprint $table) {
          // 🔗 Relación
    $table->foreignId('factura_id')->constrained()->cascadeOnDelete();

    // 📦 Producto
    $table->string('descripcion');
    $table->string('unidad_medida')->nullable();

    // 🔢 Cantidad y precios
    $table->integer('cantidad');
    $table->decimal('precio', 12, 2);
    $table->decimal('descuento', 12, 2)->default(0); // monto fijo
    $table->decimal('descuento_porcentaje', 5, 2)->default(0); // %
    // 💰 ITBIS y total
    $table->decimal('itbis', 12, 2)->default(0);
    $table->decimal('total', 12, 2);

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
        Schema::dropIfExists('factura_detalle');
    }
};
