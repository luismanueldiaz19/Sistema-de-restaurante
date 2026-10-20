<?php

declare(strict_types=1);

namespace App\Modules\Inventario\Exceptions;

use Exception;
use Illuminate\Http\JsonResponse;

class InventarioException extends Exception
{
    public function render(): JsonResponse
    {
        return response()->json([
            'success' => false,
            'message' => $this->getMessage(),
        ], $this->getCode() >= 400 && $this->getCode() <= 500 ? $this->getCode() : 400);
    }
}
