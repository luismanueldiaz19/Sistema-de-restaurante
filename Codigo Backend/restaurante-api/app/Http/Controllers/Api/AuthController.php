<?php

namespace App\Http\Controllers\Api;

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
    'email'    => 'required|email|unique:users,email',
    'password' => 'required|min:6'
], [
    'email.unique' => 'Este correo ya está registrado'
]);

        $user = User::create([
            'name'     => $request->name,
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
    // ✅ 1. Validación
    $validator = Validator::make($request->all(), [
        'email'    => 'required|email',
        'password' => 'required|min:6'
    ]);

    if ($validator->fails()) {
        return response()->json([
            'status'  => false,
            'message' => 'Datos inválidos',
            'errors'  => $validator->errors()
        ], 422);
    }

    // ✅ 2. Buscar usuario
    $user = User::where('email', $request->email)->first();

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
                'id'    => $user->id,
                'name'  => $user->name,
                'email' => $user->email,
            ],
            'roles' => $roles,
            'permissions' => $permissions,
            'token' => $token
        ]
    ], 200);
}

    // ✅ LOGOUT
    public function logout(Request $request) {
    
     $request->user()->currentAccessToken()->delete();

      return response()->json([
          'status'  => true,
          'message' => 'Sesión cerrada correctamente'
      ]);
   }

    // ✅ USUARIO ACTUAL
    public function me(Request $request)
    {
        return response()->json($request->user());
    }
}
