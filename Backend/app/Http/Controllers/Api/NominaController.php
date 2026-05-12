<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Empleado;
use App\Models\Nomina;
use App\Models\NominaDetalle;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class NominaController extends Controller
{
    /**
     * Listado de empleados activos
     */
    public function getEmpleados()
    {
        $empleados = Empleado::where('activo', true)->get();
        return response()->json([
            'status' => true,
            'data' => $empleados
        ]);
    }

    /**
     * Historial de nóminas
     */
    public function index()
    {
        $nominas = Nomina::with('detalles')->orderBy('fecha_creacion', 'desc')->get();
        return response()->json([
            'status' => true,
            'data' => $nominas
        ]);
    }

    /**
     * Crear una nueva nómina
     */
    public function store(Request $request)
    {
        $validated = $request->validate([
            'periodo' => 'required|string',
            'fecha_creacion' => 'required|date',
            'detalles' => 'required|array',
            'detalles.*.empleado_id' => 'required|exists:empleados,id',
            'detalles.*.nombre_empleado' => 'required|string',
            'detalles.*.salario_bruto' => 'required|numeric',
            'detalles.*.horas_extras' => 'nullable|numeric',
            'detalles.*.incentivos' => 'nullable|numeric',
            'detalles.*.feriados' => 'nullable|numeric',
            'detalles.*.afp_empleado' => 'required|numeric',
            'detalles.*.sfs_empleado' => 'required|numeric',
            'detalles.*.isr_retencion' => 'required|numeric',
            'detalles.*.otros_descuentos' => 'required|numeric',
            'detalles.*.salario_neto' => 'required|numeric',
        ]);

        try {
            return DB::transaction(function () use ($validated) {
                $nomina = Nomina::create([
                    'periodo' => $validated['periodo'],
                    'fecha_creacion' => $validated['fecha_creacion'],
                    'estado' => 'Borrador',
                    'total_bruto' => 0,
                    'total_retenciones' => 0,
                    'total_neto' => 0,
                ]);

                $totalBruto = 0;
                $totalRetenciones = 0;
                $totalNeto = 0;

                foreach ($validated['detalles'] as $det) {
                    $totalBruto += $det['salario_bruto'];
                    $totalRetenciones += ($det['afp_empleado'] + $det['sfs_empleado'] + $det['isr_retencion'] + $det['otros_descuentos']);
                    $totalNeto += $det['salario_neto'];

                    NominaDetalle::create([
                        'nomina_id' => $nomina->id,
                        'empleado_id' => $det['empleado_id'],
                        'nombre_empleado' => $det['nombre_empleado'],
                        'salario_bruto' => $det['salario_bruto'],
                        'horas_extras' => $det['horas_extras'] ?? 0,
                        'incentivos' => $det['incentivos'] ?? 0,
                        'feriados' => $det['feriados'] ?? 0,
                        'afp_empleado' => $det['afp_empleado'],
                        'sfs_empleado' => $det['sfs_empleado'],
                        'isr_retencion' => $det['isr_retencion'],
                        'otros_descuentos' => $det['otros_descuentos'],
                        'salario_neto' => $det['salario_neto'],
                    ]);
                }

                $nomina->update([
                    'total_bruto' => $totalBruto,
                    'total_retenciones' => $totalRetenciones,
                    'total_neto' => $totalNeto,
                ]);

                return response()->json([
                    'status' => true,
                    'message' => 'Nómina creada exitosamente',
                    'data' => $nomina->load('detalles')
                ], 201);
            });
        } catch (\Exception $e) {
            return response()->json([
                'status' => false,
                'message' => 'Error al crear la nómina: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Actualizar el estado de la nómina (Ej: de Borrador a Pagado)
     */
    public function updateStatus(Request $request, $id)
    {
        $validated = $request->validate([
            'estado' => 'required|string|in:Borrador,Pagado,Anulado',
        ]);

        $nomina = Nomina::findOrFail($id);
        $nomina->update(['estado' => $validated['estado']]);

        return response()->json([
            'status' => true,
            'message' => 'Estado de nómina actualizado',
            'data' => $nomina
        ]);
    }
}
