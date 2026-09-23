<?php

namespace App\Modules\Auth\Http\Controllers;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Modules\Auth\Http\Requests\LoginRequest;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;

class AuthController extends Controller
{
    /**
     * Authenticate user and generate a Sanctum token.
     */
    public function login(LoginRequest $request)
    {
        $user = User::where('email', $request->email)->first();

        // Verificamos si el usuario existe y si la contraseña es correcta
        if (!$user || !Hash::check($request->password, $user->password)) {
            return response()->json([
                'status'  => false,
                'message' => 'Credenciales incorrectas'
            ], 401);
        }

        // Creamos el token de acceso
        $token = $user->createToken('api_v2_token')->plainTextToken;

        return response()->json([
            'status' => true,
            'message' => 'Autenticación exitosa',
            'data' => [
                'user' => [
                    'id'    => $user->id,
                    'name'  => $user->name,
                    'email' => $user->email,
                ],
                'token' => $token
            ]
        ], 200);
    }

    /**
     * Revoke the current user's token.
     */
    public function logout(Request $request)
    {
        // Revocamos el token con el que se hizo esta petición
        $request->user()->currentAccessToken()->delete();

        return response()->json([
            'status'  => true,
            'message' => 'Sesión cerrada correctamente (Token revocado)'
        ], 200);
    }
}
