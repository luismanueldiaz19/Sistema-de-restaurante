<?php

namespace App\Http\Controllers\Api\Auth;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\RateLimiter;
use Illuminate\Support\Facades\Validator;

class AuthController extends Controller
{
    // ✅ REGISTRO
    public function register(Request $request)
    {
        $request->validate([
            'name'     => 'required',
            'username' => 'nullable|string|unique:users,username',
            'email'    => 'required|email|unique:users,email',
            'password' => 'required|min:6'
        ], [
            'email.unique'    => 'Este correo ya está registrado',
            'username.unique' => 'Este nombre de usuario ya está registrado',
        ]);

        $username = $request->username ?? explode('@', $request->email)[0];

        $user = User::create([
            'name'     => $request->name,
            'username' => $username,
            'email'    => $request->email,
            'password' => Hash::make($request->password)
        ]);

        $token = $user->createToken('api_token')->plainTextToken;

        return response()->json([
            'status' => true,
            'user'   => $user,
            'token'  => $token
        ]);
    }

    // ✅ LOGIN
    public function login(Request $request) {
        $loginId = (string) ($request->input('username') ?? $request->input('email'));

        // ✅ 1. Validación
        $validator = Validator::make([
            'login'    => $loginId,
            'password' => $request->input('password'),
        ], [
            'login'    => 'required|string',
            'password' => 'required|string|min:4'
        ], [
            'login.required' => 'El usuario o correo es obligatorio',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'status'  => false,
                'message' => 'Datos inválidos',
                'errors'  => $validator->errors()
            ], 422);
        }

        // ✅ 2. Buscar usuario por username o email
        $user = User::where('username', $loginId)
            ->orWhere('email', $loginId)
            ->first();

        if (!$user || !Hash::check($request->password, $user->password)) {
            return response()->json([
                'status'  => false,
                'message' => 'Credenciales incorrectas'
            ], 401);
        }

        // ✅ 3. Eliminar tokens anteriores (opcional pero recomendado)
        $user->tokens()->delete();

        // ✅ 4. Crear token
        $token = $user->createToken('api_token')->plainTextToken;

        // ✅ 5. Optimizar permisos
        $roles = $user->getRoleNames();
        $permissions = $user->getAllPermissions()->pluck('name');

        return response()->json([
            'status' => true,
            'message' => 'Login exitoso',
            'data' => [
                'user' => [
                    'id'       => $user->id,
                    'name'     => $user->name,
                    'username' => $user->username,
                    'email'    => $user->email,
                ],
                'token'       => $token,
                'roles'       => $roles,
                'permissions' => $permissions
            ]
        ]);
    }

    // ✅ LOGOUT
    public function logout(Request $request) {
        $request->user()->currentAccessToken()->delete();

        return response()->json([
            'status'  => true,
            'message' => 'Sesión cerrada correctamente'
        ]);
    }

    // ✅ ME (Usuario autenticado con roles y permisos)
    public function me(Request $request) {
        $user = $request->user();

        return response()->json([
            'status' => true,
            'data'   => [
                'user'        => [
                    'id'       => $user->id,
                    'name'     => $user->name,
                    'username' => $user->username,
                    'email'    => $user->email,
                ],
                'roles'       => $user->getRoleNames(),
                'permissions' => $user->getAllPermissions()->pluck('name')
            ]
        ]);
    }
}
