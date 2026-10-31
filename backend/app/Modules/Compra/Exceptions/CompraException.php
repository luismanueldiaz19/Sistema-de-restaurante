<?php

declare(strict_types=1);

namespace App\Modules\Compra\Exceptions;

use Exception;
use Illuminate\Http\JsonResponse;

class CompraException extends Exception
{
    public function render(): JsonResponse
    {
        return response()->json([
            'success' => false,
            'message' => $this->getMessage(),
        ], 400);
    }
}
