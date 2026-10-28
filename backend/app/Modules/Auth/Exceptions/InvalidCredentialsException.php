<?php

declare(strict_types=1);

namespace App\Modules\Auth\Exceptions;

use Exception;
use Illuminate\Http\JsonResponse;

class InvalidCredentialsException extends Exception
{
    public function __construct(string $message = 'Credenciales incorrectas')
    {
        parent::__construct($message, 401);
    }

    public function render(): JsonResponse
    {
        return response()->json([
            'status'  => false,
            'message' => $this->getMessage(),
        ], 401);
    }
}

