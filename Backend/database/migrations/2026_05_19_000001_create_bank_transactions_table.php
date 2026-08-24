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
        Schema::create('bank_transactions', function (Blueprint $table) {
            $table->id();
            $table->foreignId('bank_account_id')->constrained('bank_accounts')->onDelete('cascade');
            $table->date('date');
            $table->string('type'); // deposit, withdrawal, fee, interest, transfer
            $table->decimal('amount', 15, 2); // Positive for deposit, negative for withdrawal
            $table->string('reference')->nullable();
            $table->text('description')->nullable();
            $table->string('status')->default('pending'); // pending, transit, reconciled
            $table->foreignId('journal_entry_id')->nullable()->constrained('asientos_contables')->nullOnDelete();
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('bank_transactions');
    }
};
