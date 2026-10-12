<?php

declare(strict_types=1);

namespace App\Modules\Pedido\Exceptions;

use Exception;
use Illuminate\Http\JsonResponse;

class PedidoException extends Exception
{
    public function render(): JsonResponse
    {
        return response()->json([
            'success' => false,
            'message' => $this->getMessage(),
        ], 400);
    }
}
