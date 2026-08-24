<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('bank_accounts', function (Blueprint $table) {
            $table->id();
            $table->foreignId('bank_id')->constrained('banks')->onDelete('cascade');
            $table->string('name');
            $table->string('account_number');
            $table->string('currency')->default('DOP');
            $table->decimal('current_balance', 15, 2)->default(0);
            $table->foreignId('accounting_account_id')->constrained('catalogo_cuentas')->restrictOnDelete();
            $table->boolean('is_active')->default(true);
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('bank_accounts');
    }
};
