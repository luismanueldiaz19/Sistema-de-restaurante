<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Empleado;
use Illuminate\Http\Request;

class EmpleadoController extends Controller
{
    public function index()
    {
        $empleados = Empleado::orderBy('nombre')->get();
        return response()->json([
            'status' => true,
            'data' => $empleados
        ]);
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'nombre' => 'required|string|max:100',
            'cedula' => 'required|string|unique:empleados,cedula',
            'salario_base' => 'required|numeric|min:0',
            'tipo_nomina' => 'required|string|in:Semanal,Quincenal,Mensual',
            'turno' => 'nullable|string|max:100',
            'fecha_ingreso' => 'required|date',
            'cargo' => 'nullable|string|max:100',
        ]);

        $empleado = Empleado::create($validated);

        return response()->json([
            'status' => true,
            'message' => 'Empleado creado exitosamente',
            'data' => $empleado
        ], 201);
    }

    public function update(Request $request, $id)
    {
        $empleado = Empleado::findOrFail($id);

        $validated = $request->validate([
            'nombre' => 'required|string|max:100',
            'cedula' => 'required|string|unique:empleados,cedula,' . $id,
            'salario_base' => 'required|numeric|min:0',
            'tipo_nomina' => 'required|string|in:Semanal,Quincenal,Mensual',
            'turno' => 'nullable|string|max:100',
            'fecha_ingreso' => 'required|date',
            'cargo' => 'nullable|string|max:100',
            'activo' => 'required|boolean',
        ]);

        $empleado->update($validated);

        return response()->json([
            'status' => true,
            'message' => 'Empleado actualizado exitosamente',
            'data' => $empleado
        ]);
    }

    public function toggleStatus($id)
    {
        $empleado = Empleado::findOrFail($id);
        $empleado->activo = !$empleado->activo;
        $empleado->save();

        return response()->json([
            'status' => true,
            'message' => 'Estado del empleado actualizado',
            'data' => $empleado
        ]);
    }
}
