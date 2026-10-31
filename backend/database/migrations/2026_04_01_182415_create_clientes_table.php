<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class () extends Migration {
    /**
     * Run the migrations.
     */
    public function up()
    {
        Schema::create('clientes', function (Blueprint $table) {

            $table->id();
            $table->string('nombre');
            $table->string('rnc_cedula')->nullable();
            $table->string('email')->nullable();
            $table->string('telefono')->nullable();
            $table->string('direccion')->nullable();
            
            // Configuración Financiera
            $table->enum('tipo_cliente', ['consumidor_final', 'credito', 'gubernamental', 'especial'])->default('consumidor_final');
            $table->decimal('limite_credito', 15, 2)->default(0);
            $table->decimal('saldo_actual', 15, 2)->default(0);
            $table->integer('dias_credito')->default(0);
            $table->string('cuenta_contable')->nullable();
            $table->decimal('descuento_fijo', 5, 2)->default(0); // Porcentaje
            
            $table->boolean('activo')->default(true);
            $table->text('notas')->nullable();
            $table->timestamps();

        });
    }

    /**
     * Reverse the migrations.
     */
    public function down()
    {
        Schema::dropIfExists('clientes');
    }
};
