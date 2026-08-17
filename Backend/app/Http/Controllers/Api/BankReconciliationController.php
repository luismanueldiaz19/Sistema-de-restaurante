<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\BankReconciliation;
use Illuminate\Http\Request;

class BankReconciliationController extends Controller
{
    public function index()
    {
        $reconciliations = BankReconciliation::with(['bankAccount', 'reconciledBy'])->get();
        return response()->json(['data' => $reconciliations], 200);
    }
}
