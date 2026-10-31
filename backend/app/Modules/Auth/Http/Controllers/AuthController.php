<?php

declare(strict_types=1);

namespace App\Modules\Auth\Http\Controllers;

use App\Http\Controllers\Controller;
use App\Modules\Auth\Exceptions\InvalidCredentialsException;
use App\Modules\Auth\Http\Requests\LoginRequest;
use App\Modules\Auth\Services\AuthService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class AuthController extends Controller
{
    public function __construct(
        private readonly AuthService $authService
    ) {}

    /**
     * Authenticate user by username & password and generate a Sanctum token.
     */
    public function login(LoginRequest $request): JsonResponse
    {
        try {
            $data = $this->authService->login(
                username: (string) $request->input('username'),
                password: (string) $request->input('password')
            );

            return response()->json([
                'status'  => true,
                'message' => 'Autenticación exitosa',
                'data'    => $data,
            ], 200);
        } catch (InvalidCredentialsException $e) {
            return response()->json([
                'status'  => false,
                'message' => $e->getMessage(),
            ], 401);
        }
    }

    /**
     * Revoke the current user's token.
     */
    public function logout(Request $request): JsonResponse
    {
        $this->authService->logout($request->user());

        return response()->json([
            'status'  => true,
            'message' => 'Sesión cerrada correctamente (Token revocado)',
        ], 200);
    }
}
