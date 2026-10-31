<?php

declare(strict_types=1);

namespace App\Modules\Cotizacion\Exceptions;

use Exception;
use Illuminate\Http\JsonResponse;

class CotizacionException extends Exception
{
    public function render(): JsonResponse
    {
        return response()->json([
            'success' => false,
            'message' => $this->getMessage(),
        ], 400);
    }
}
