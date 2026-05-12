<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('empleados', function (Blueprint $table) {
            $table->id();
            $table->string('nombre');
            $table->string('cedula')->unique();
            $table->decimal('salario_base', 12, 2);
            $table->date('fecha_ingreso');
            $table->string('cargo')->nullable();
            $table->boolean('activo')->default(true);
            $table->timestamps();
        });

        Schema::create('nominas', function (Blueprint $table) {
            $table->id();
            $table->string('periodo'); // Ejemplo: 2024-05
            $table->date('fecha_creacion');
            $table->enum('estado', ['Borrador', 'Pagado', 'Anulado'])->default('Borrador');
            $table->decimal('total_bruto', 12, 2)->default(0);
            $table->decimal('total_retenciones', 12, 2)->default(0);
            $table->decimal('total_neto', 12, 2)->default(0);
            $table->timestamps();
        });

        Schema::create('nomina_detalles', function (Blueprint $table) {
            $table->id();
            $table->foreignId('nomina_id')->constrained('nominas')->onDelete('cascade');
            $table->foreignId('empleado_id')->constrained('empleados');
            $table->string('nombre_empleado');
            $table->decimal('salario_bruto', 12, 2);
            $table->decimal('horas_extras', 12, 2)->default(0);
            $table->decimal('incentivos', 12, 2)->default(0);
            $table->decimal('feriados', 12, 2)->default(0);
            $table->decimal('afp_empleado', 12, 2);
            $table->decimal('sfs_empleado', 12, 2);
            $table->decimal('isr_retencion', 12, 2);
            $table->decimal('otros_descuentos', 12, 2)->default(0);
            $table->decimal('salario_neto', 12, 2);
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('nomina_detalles');
        Schema::dropIfExists('nominas');
        Schema::dropIfExists('empleados');
    }
};
