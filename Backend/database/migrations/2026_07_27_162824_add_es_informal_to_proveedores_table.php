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
        Schema::table('proveedores', function (Blueprint $table) {
            $table->boolean('es_informal')->default(false)->after('rnc')->comment('Indica si el proveedor es informal (requiere retención de ITBIS y NCF B11/E41)');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('proveedores', function (Blueprint $table) {
            $table->dropColumn('es_informal');
        });
    }
};
