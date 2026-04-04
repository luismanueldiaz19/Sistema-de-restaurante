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
        Schema::create('ncf_secuencias', function (Blueprint $table) {
            $table->id();

            $table->string('tipo', 5); // 31, 32, 33
            $table->string('nombre', 100)->nullable();

            $table->string('prefijo', 5)->default('E'); // E = electrónico

            $table->unsignedBigInteger('actual')->default(0);

            $table->unsignedBigInteger('rango_inicio')->default(1);
            $table->unsignedBigInteger('rango_fin')->default(999999999);

            $table->boolean('activo')->default(true);

            // 🔥 opcional (recomendado)
            $table->unique('tipo');
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
        Schema::dropIfExists('ncf_secuencias');
    }
};
