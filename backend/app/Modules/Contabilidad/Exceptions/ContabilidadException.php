<?php
declare(strict_types=1);

namespace App\Modules\Contabilidad\Exceptions;

use Exception;

use Illuminate\Http\JsonResponse;

class ContabilidadException extends Exception
{
    public function render(): JsonResponse
    {
        return response()->json([
            'success' => false,
            'message' => $this->getMessage(),
        ], 400);
    }
}
