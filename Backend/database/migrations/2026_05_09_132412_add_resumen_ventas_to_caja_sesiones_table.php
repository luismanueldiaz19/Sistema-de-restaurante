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
        Schema::table('caja_sesiones', function (Blueprint $table) {
            $table->json('resumen_ventas')->nullable()->after('desglose_efectivo');
        });
    }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down()
    {
        Schema::table('caja_sesiones', function (Blueprint $table) {
            $table->dropColumn('resumen_ventas');
        });
    }
};
