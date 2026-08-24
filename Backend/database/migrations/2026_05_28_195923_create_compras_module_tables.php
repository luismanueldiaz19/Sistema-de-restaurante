<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up()
    {
        // 1. Proveedores
        Schema::create('proveedores', function (Blueprint $table) {
            $table->id();
            $table->string('nombre');
            $table->string('rnc')->nullable();
            $table->boolean('es_informal')->default(false)->comment('Indica si el proveedor es informal (requiere retención de ITBIS y NCF B11/E41)');
            $table->string('telefono')->nullable();
            $table->string('email')->nullable();
            $table->text('direccion')->nullable();
            $table->foreignId('cuenta_contable_cxp_id')->nullable()->constrained('catalogo_cuentas')->nullOnDelete();
            $table->foreignId('cuenta_contable_gasto_id')->nullable()->constrained('catalogo_cuentas')->nullOnDelete();
            $table->boolean('activo')->default(true);
            $table->timestamps();
        });

        // 2. Ordenes de Compra
        Schema::create('ordenes_compra', function (Blueprint $table) {
            $table->id();
            $table->foreignId('proveedor_id')->constrained('proveedores')->restrictOnDelete();
            $table->string('numero_orden')->unique();
            $table->date('fecha');
            $table->date('fecha_vencimiento')->nullable();
            $table->decimal('subtotal', 12, 2)->default(0);
            $table->decimal('descuento_total', 12, 2)->default(0);
            $table->decimal('itbis', 12, 2)->default(0);
            $table->decimal('total', 12, 2)->default(0);
            $table->enum('estado', ['BORRADOR', 'ENVIADA', 'RECIBIDA', 'CANCELADA'])->default('BORRADOR');
            $table->text('notas')->nullable();
            $table->foreignId('usuario_id')->constrained('users')->restrictOnDelete();
            $table->timestamps();
        });

        Schema::create('orden_compra_detalles', function (Blueprint $table) {
            $table->id();
            $table->foreignId('orden_compra_id')->constrained('ordenes_compra')->cascadeOnDelete();
            $table->foreignId('producto_id')->nullable()->constrained('productos')->restrictOnDelete();
            $table->string('descripcion')->nullable(); // For expenses/services without product
            $table->decimal('cantidad', 10, 2);
            $table->decimal('costo_esperado', 10, 2);
            $table->decimal('itbis', 10, 2)->default(0);
            $table->decimal('subtotal', 10, 2);
            $table->decimal('total', 10, 2)->default(0);
            $table->timestamps();
        });

        // 3. Compras
        Schema::create('compras', function (Blueprint $table) {
            $table->id();
            $table->foreignId('proveedor_id')->constrained('proveedores')->restrictOnDelete();
            $table->foreignId('orden_compra_id')->nullable()->constrained('ordenes_compra')->nullOnDelete();
            $table->string('numero_factura_proveedor');
            $table->string('ncf')->nullable();
            $table->date('fecha_compra');
            $table->date('fecha_vencimiento')->nullable();
            $table->enum('tipo_compra', ['CONTADO', 'CREDITO']);
            $table->decimal('subtotal', 12, 2)->default(0);
            $table->decimal('impuestos', 12, 2)->default(0);
            $table->decimal('total', 12, 2)->default(0);
            $table->enum('estado', ['PENDIENTE', 'PAGADA', 'ANULADA'])->default('PENDIENTE');
            $table->foreignId('usuario_id')->constrained('users')->restrictOnDelete();
            $table->foreignId('asiento_id')->nullable()->constrained('asientos_contables')->nullOnDelete();
            $table->text('notas')->nullable();
            $table->timestamps();
        });

        Schema::create('compra_detalles', function (Blueprint $table) {
            $table->id();
            $table->foreignId('compra_id')->constrained('compras')->cascadeOnDelete();
            $table->foreignId('producto_id')->nullable()->constrained('productos')->restrictOnDelete();
            $table->string('descripcion')->nullable();
            $table->foreignId('cuenta_contable_id')->nullable()->constrained('catalogo_cuentas')->restrictOnDelete();
            $table->decimal('cantidad', 10, 2);
            $table->decimal('costo_unitario', 10, 2);
            $table->decimal('subtotal', 10, 2);
            $table->decimal('impuesto_monto', 10, 2)->default(0);
            $table->decimal('total', 10, 2);
            $table->timestamps();
        });

        // 4. Cuentas por Pagar
        Schema::create('cuentas_por_pagar', function (Blueprint $table) {
            $table->id();
            $table->foreignId('proveedor_id')->constrained('proveedores')->restrictOnDelete();
            $table->foreignId('compra_id')->constrained('compras')->restrictOnDelete();
            $table->decimal('monto_original', 12, 2);
            $table->decimal('balance_pendiente', 12, 2);
            $table->date('fecha_vencimiento');
            $table->enum('estado', ['PENDIENTE', 'PARCIAL', 'PAGADA'])->default('PENDIENTE');
            $table->timestamps();
        });

        // 5. Pagos a Cuentas por Pagar
        Schema::create('pagos_compras', function (Blueprint $table) {
            $table->id();
            $table->foreignId('cxp_id')->constrained('cuentas_por_pagar')->restrictOnDelete();
            $table->decimal('monto_pagado', 12, 2);
            $table->date('fecha_pago');
            $table->foreignId('metodo_pago_id')->constrained('metodo_pagos')->restrictOnDelete();
            $table->string('referencia')->nullable();
            $table->foreignId('cuenta_origen_id')->constrained('catalogo_cuentas')->restrictOnDelete();
            $table->foreignId('asiento_id')->nullable()->constrained('asientos_contables')->nullOnDelete();
            $table->foreignId('usuario_id')->constrained('users')->restrictOnDelete();
            $table->timestamps();
        });

        // 6. Devoluciones de Compras
        Schema::create('devoluciones_compras', function (Blueprint $table) {
            $table->id();
            $table->foreignId('compra_id')->constrained('compras')->restrictOnDelete();
            $table->date('fecha_devolucion');
            $table->string('motivo');
            $table->decimal('total_devuelto', 12, 2);
            $table->foreignId('asiento_id')->nullable()->constrained('asientos_contables')->nullOnDelete();
            $table->foreignId('usuario_id')->constrained('users')->restrictOnDelete();
            $table->timestamps();
        });
    }

    public function down()
    {
        Schema::dropIfExists('devoluciones_compras');
        Schema::dropIfExists('pagos_compras');
        Schema::dropIfExists('cuentas_por_pagar');
        Schema::dropIfExists('compra_detalles');
        Schema::dropIfExists('compras');
        Schema::dropIfExists('orden_compra_detalles');
        Schema::dropIfExists('ordenes_compra');
        Schema::dropIfExists('proveedores');
    }
};
