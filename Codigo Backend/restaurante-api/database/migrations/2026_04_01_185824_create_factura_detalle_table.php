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
        Schema::create('factura_detalle', function (Blueprint $table) {
            $table->id();

    $table->foreignId('factura_id')->constrained()->onDelete('cascade');

    $table->string('descripcion');
    $table->integer('cantidad');
    $table->decimal('precio', 10, 2);

    $table->decimal('itbis', 10, 2)->default(0);
    $table->decimal('subtotal', 10, 2);

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
