<?php

namespace App\Http\Controllers\Api\Facturacion;

use App\Http\Controllers\Controller;
use App\Models\NcfSecuencia;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class NcfSecuenciaController extends Controller
{
    /**
     * GET /api/ncf-secuencias
     * Por defecto devuelve secuencias activas (usado en POS Vender).
     * Con ?all=1 devuelve todas las secuencias con sus rangos y métricas (usado en DGII -> NCF).
     */
    public function index(Request $request)
    {
        try {
            $includeAll = $request->boolean('all');

            $query = NcfSecuencia::query()->orderBy('prefijo')->orderBy('tipo');

            if (!$includeAll) {
                $query->select('id', 'tipo', 'nombre', 'prefijo', 'actual', 'rango_inicio', 'rango_fin', 'activo')
                      ->where('activo', true);
            }

            $tipos = $query->get();

            return response()->json([
                'status' => 200,
                'data'   => $tipos,
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'status'  => 500,
                'message' => 'Error al obtener secuencias NCF',
                'error'   => $e->getMessage(),
            ], 500);
        }
    }

    /**
     * GET /api/ncf-secuencias/{id}
     */
    public function show($id)
    {
        $sec = NcfSecuencia::find($id);
        if (!$sec) {
            return response()->json(['status' => 404, 'message' => 'Secuencia no encontrada'], 404);
        }

        return response()->json(['status' => 200, 'data' => $sec]);
    }

    /**
     * POST /api/ncf-secuencias
     */
    public function store(Request $request)
    {
        $validated = $request->validate([
            'prefijo'      => ['required', 'string', 'in:E,B'],
            'tipo'         => ['required', 'string', 'max:5', Rule::unique('ncf_secuencias', 'tipo')],
            'nombre'       => ['required', 'string', 'max:100'],
            'rango_inicio' => ['required', 'integer', 'min:1'],
            'rango_fin'    => ['required', 'integer', 'gte:rango_inicio'],
            'actual'       => ['required', 'integer', 'min:0', 'lte:rango_fin'],
            'activo'       => ['nullable', 'boolean'],
        ]);

        $sec = NcfSecuencia::create([
            'prefijo'      => strtoupper($validated['prefijo']),
            'tipo'         => preg_replace('/[^0-9]/', '', $validated['tipo']),
            'nombre'       => trim($validated['nombre']),
            'rango_inicio' => (int) $validated['rango_inicio'],
            'rango_fin'    => (int) $validated['rango_fin'],
            'actual'       => (int) $validated['actual'],
            'activo'       => $validated['activo'] ?? true,
        ]);

        return response()->json([
            'status'  => 201,
            'message' => "Secuencia {$sec->prefijo}{$sec->tipo} creada correctamente.",
            'data'    => $sec,
        ], 201);
    }

    /**
     * PUT /api/ncf-secuencias/{id}
     */
    public function update(Request $request, $id)
    {
        $sec = NcfSecuencia::findOrFail($id);

        $validated = $request->validate([
            'prefijo'      => ['required', 'string', 'in:E,B'],
            'tipo'         => ['required', 'string', 'max:5', Rule::unique('ncf_secuencias', 'tipo')->ignore($sec->id)],
            'nombre'       => ['required', 'string', 'max:100'],
            'rango_inicio' => ['required', 'integer', 'min:1'],
            'rango_fin'    => ['required', 'integer', 'gte:rango_inicio'],
            'actual'       => ['required', 'integer', 'min:0', 'lte:rango_fin'],
            'activo'       => ['nullable', 'boolean'],
        ]);

        $sec->update([
            'prefijo'      => strtoupper($validated['prefijo']),
            'tipo'         => preg_replace('/[^0-9]/', '', $validated['tipo']),
            'nombre'       => trim($validated['nombre']),
            'rango_inicio' => (int) $validated['rango_inicio'],
            'rango_fin'    => (int) $validated['rango_fin'],
            'actual'       => (int) $validated['actual'],
            'activo'       => $validated['activo'] ?? $sec->activo,
        ]);

        return response()->json([
            'status'  => 200,
            'message' => "Secuencia {$sec->prefijo}{$sec->tipo} actualizada correctamente.",
            'data'    => $sec,
        ]);
    }

    /**
     * PATCH /api/ncf-secuencias/{id}/toggle
     */
    public function toggleActivo($id)
    {
        $sec = NcfSecuencia::findOrFail($id);
        $sec->activo = !$sec->activo;
        $sec->save();

        $estadoTxt = $sec->activo ? 'activada' : 'desactivada';

        return response()->json([
            'status'  => 200,
            'message' => "Secuencia {$sec->prefijo}{$sec->tipo} {$estadoTxt}.",
            'data'    => $sec,
        ]);
    }
}
