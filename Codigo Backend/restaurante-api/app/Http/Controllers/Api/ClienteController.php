<?php

namespace App\Http\Controllers\Api;
use App\Http\Controllers\Controller;
use App\Models\Cliente; 
use Illuminate\Http\Request;

use Illuminate\Support\Facades\Validator;

class ClienteController extends Controller {
    // 🔍 LISTAR
    public function index()
    {
        $clientes = Cliente::latest()->get();
        return response()->json($clientes);
    }

    
    // ➕ CREAR UN CLIENTE
public function store(Request $request) {

    $validator = Validator::make($request->all(), [
        'nombre' => 'required',
        'telefono' => 'required',
    ]);

    if ($validator->fails()) {
        $data = [
            'message' => 'Error en la validación de los datos',
            'errors'  => $validator->errors(), // ✅ aquí va errors()
            'status'  => 400
        ];
        return response()->json($data, 400);
    }

    $cliente = Cliente::create([
        'nombre'   => $request->nombre,
        'telefono' => $request->telefono
    ]);

    if (!$cliente) {
        $data = [
            'message' => 'Error al crear cliente',
            'status'  => 500
        ];
        return response()->json($data, 500);
    }

    $data = [
        'message' => 'Cliente creado correctamente',
        'status'  => 201,
        'data'    => $cliente
    ];

    return response()->json($data, 201);
}

 
     
     


 


    // 🔍 VER UNO
    public function show($id) {
        
    if (!is_numeric($id)) {
        return response()->json([
            'success' => false,
            'message' => 'El ID debe ser numérico'
        ], 400);
    }
    try {
        $cliente = Cliente::findOrFail($id);

        return response()->json([
            'success' => true,
            'data' => $cliente
        ], 200);

    } catch (\Illuminate\Database\Eloquent\ModelNotFoundException $e) {
        return response()->json([
            'success' => false,
            'message' => 'Cliente no encontrado'
        ], 404);

    } catch (\Exception $e) {
        return response()->json([
            'success' => false,
            'message' => 'Error interno del servidor',
            'error' => $e->getMessage() // opcional (quítalo en producción)
        ], 500);
    }
}
    // public function show($id) {
    //     $cliente = Cliente::findOrFail($id);
    //     return response()->json($cliente);
    // }

    // ✏️ ACTUALIZAR
    public function update(Request $request, $id)
    {
        $cliente = Cliente::findOrFail($id);

        $request->validate([
            'nombre' => 'required'
        ]);

        $cliente->update($request->only([
            'nombre',
            'telefono',
            'direccion',
            'documento',
            'email'
        ]));

        return response()->json([
            'status'  => true,
            'message' => 'Cliente actualizado correctamente',
            'data'    => $cliente
        ]);
    }

    // ❌ ELIMINAR
    public function destroy($id) {

        $cliente = Cliente::find($id);

        if(!$cliente){
            $data = [
                'message' => 'Cliente no encontrado',
                'status' => 404,
            ];
            return response()->json($data, 404, $headers);

        }


        $cliente->delete();
          $data = [
               'message' => 'Cliente eliminado',
                'status' => 200
            ];

      return response()->json($data, 200, $headers);
    }


}
