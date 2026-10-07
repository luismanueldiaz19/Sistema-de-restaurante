<?php

declare(strict_types=1);

namespace App\Modules\Producto\Exceptions;

use Exception;
use Illuminate\Http\JsonResponse;

class ProductoException extends Exception
{
    public function render(): JsonResponse
    {
        return response()->json([
            'success' => false,
            'message' => $this->getMessage(),
        ], 400);
    }
}
