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
        Schema::table('compra_detalles', function (Blueprint $table) {
            $table->string('presentacion')->nullable()->after('descripcion');
            $table->decimal('factor_conversion', 8, 2)->default(1)->after('presentacion');
        });
    }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down()
    {
        Schema::table('compra_detalles', function (Blueprint $table) {
            $table->dropColumn(['presentacion', 'factor_conversion']);
        });
    }
};
