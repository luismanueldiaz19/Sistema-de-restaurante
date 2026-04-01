<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;

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
    public function login(Request $request)
    {
        $user = User::where('email', $request->email)->first();

        if (!$user || !Hash::check($request->password, $user->password)) {
            return response()->json([
                'status'  => false,
                'message' => 'Credenciales incorrectas'
            ], 401);
        }

        $token = $user->createToken('api_token')->plainTextToken;

        return response()->json([
            'status' => true,

            // 👇 SOLO DATOS NECESARIOS
            'user' => [
                'id'    => $user->id,
                'name'  => $user->name,
                'email' => $user->email,
            ],

            'roles' => $user->getRoleNames(),

            'permissions' => $user->getAllPermissions()->pluck('name'),

            'token' => $token
        ]);
    }

    // ✅ LOGOUT
    public function logout(Request $request)
    {
        $request->user()->tokens()->delete();

        return response()->json([
            'status'  => true,
            'message' => 'Sesión cerrada'
        ]);
    }

    // ✅ USUARIO ACTUAL
    public function me(Request $request)
    {
        return response()->json($request->user());
    }
}
