<?php

namespace App\Http\Controllers\Api\Facturacion;
use App\Http\Controllers\Controller;
use App\Models\Cliente; 
use Illuminate\Http\Request;

use Illuminate\Support\Facades\Validator;
use Illuminate\Database\Eloquent\ModelNotFoundException;
use Exception;
use Illuminate\Database\QueryException;

class ClienteController extends Controller {
    // 🔍 LISTAR
    public function index()  {
        $clientes = Cliente::latest()->get();
        return response()->json($clientes);
    }

    
    // ➕ CREAR UN CLIENTE
    public function store(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'nombre'          => 'required|string|max:255',
            'rnc_cedula'      => 'nullable|string|max:255',
            'email'           => 'nullable|email|max:255',
            'telefono'        => 'required|string|max:255',
            'direccion'       => 'nullable|string|max:255',
            'tipo_cliente'    => 'nullable|string|in:consumidor_final,credito,gubernamental,especial',
            'limite_credito'  => 'nullable|numeric',
            'dias_credito'    => 'nullable|integer',
            'cuenta_contable' => 'nullable|string|max:255',
            'descuento_fijo'  => 'nullable|numeric',
            'activo'          => 'nullable|boolean',
            'notas'           => 'nullable|string',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'message' => 'Error en la validación de los datos',
                'errors'  => $validator->errors(),
                'status'  => 400
            ], 400);
        }

        $cliente = Cliente::create($request->all());

        if (!$cliente) {
            return response()->json([
                'message' => 'Error al crear cliente',
                'status'  => 500
            ], 500);
        }

        return response()->json([
            'message' => 'Cliente creado correctamente',
            'status'  => 201,
            'data'    => $cliente
        ], 201);
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

    // ✏️ ACTUALIZAR
    public function update(Request $request, $id)
    {
        try {
            $cliente = Cliente::find($id);

            if (!$cliente) {
                return response()->json([
                    'message' => 'Cliente no encontrado',
                    'status'  => 404
                ], 404);
            }

            $validator = Validator::make($request->all(), [
                'nombre'          => 'required|string|max:255',
                'rnc_cedula'      => 'nullable|string|max:255',
                'email'           => 'nullable|email|max:255',
                'telefono'        => 'nullable|string|max:255',
                'direccion'       => 'nullable|string|max:255',
                'tipo_cliente'    => 'nullable|string|in:consumidor_final,credito,gubernamental,especial',
                'limite_credito'  => 'nullable|numeric',
                'dias_credito'    => 'nullable|integer',
                'cuenta_contable' => 'nullable|string|max:255',
                'descuento_fijo'  => 'nullable|numeric',
                'activo'          => 'nullable|boolean',
                'notas'           => 'nullable|string',
            ]);

            if ($validator->fails()) {
                return response()->json([
                    'message' => 'Error en la validación',
                    'errors'  => $validator->errors(),
                    'status'  => 400
                ], 400);
            }

            $cliente->update($request->all());

            return response()->json([
                'message' => 'Cliente actualizado correctamente',
                'status'  => 200,
                'data'    => $cliente
            ], 200);
        } catch (Exception $e) {
            return response()->json([
                'message' => 'Error al actualizar cliente',
                'error'   => $e->getMessage(),
                'status'  => 500
            ], 500);
        }
    }

   // ❌ ELIMINAR
public function destroy($id) {
    try {
        // 🔍 Buscar cliente
        $cliente = Cliente::find($id);

        if (!$cliente) {
            return response()->json([
                'message' => 'Cliente no encontrado',
                'status'  => 404
            ], 404);
        }

        // 🗑️ Eliminar
        $cliente->delete();

        return response()->json([
            'message' => 'Cliente eliminado correctamente',
            'status'  => 200
        ], 200);

    } catch (QueryException $e) {
        return response()->json([
        'message' => 'No se puede eliminar el cliente porque tiene registros relacionados',
        'status'  => 409
    ], 409);
}
}


}

