<?php

declare(strict_types=1);

namespace App\Modules\Auth\Services;

use App\Models\User;
use App\Modules\Auth\Exceptions\InvalidCredentialsException;
use Illuminate\Support\Facades\Hash;
use Laravel\Sanctum\PersonalAccessToken;

class AuthService
{
    /**
     * Autenticar credenciales de usuario (username o email / password) y generar token de acceso Sanctum.
     *
     * @throws InvalidCredentialsException
     */
    public function login(string $username, string $password, string $tokenName = 'api_v2_token'): array
    {
        $user = User::where('username', $username)
            ->orWhere('email', $username)
            ->first();

        if (!$user || !Hash::check($password, $user->password)) {
            throw new InvalidCredentialsException('Credenciales incorrectas');
        }

        $token = $user->createToken($tokenName)->plainTextToken;

        return [
            'user' => [
                'id'       => $user->id,
                'name'     => $user->name,
                'username' => $user->username,
                'email'    => $user->email,
            ],
            'roles'       => $user->getRoleNames(),
            'permissions' => $user->getAllPermissions()->pluck('name'),
            'token'       => $token,
        ];
    }

    /**
     * Revocar el token de acceso activo de la sesión actual del usuario.
     */
    public function logout(User $user): void
    {
        /** @var PersonalAccessToken|null $currentToken */
        $currentToken = $user->currentAccessToken();

        $currentToken?->delete();
    }
}
