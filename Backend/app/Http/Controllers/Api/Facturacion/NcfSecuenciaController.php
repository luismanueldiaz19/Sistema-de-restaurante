<?php
namespace App\Http\Controllers\Api\Facturacion;
use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\NcfSecuencia;





class NcfSecuenciaController extends Controller {
    // 🔹 GET: listar tipos de comprobantes
    public function index()  {
        try {
            $tipos = NcfSecuencia::select('id', 'tipo', 'nombre', 'prefijo')
                ->where('activo', true)
                ->orderBy('tipo')
                ->get();

            return response()->json([
                'status' => 200,
                'data' => $tipos
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'status' => 500,
                'message' => 'Error al obtener tipos',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    // 🔹 GET: uno solo
    public function show($id)
    {
        try {
            $tipo = NcfSecuencia::find($id);

            if (!$tipo) {
                return response()->json([
                    'status' => 404,
                    'message' => 'No encontrado'
                ], 404);
            }

            return response()->json([
                'status' => 200,
                'data' => $tipo
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'status' => 500,
                'message' => 'Error',
                'error' => $e->getMessage()
            ], 500);
        }
    }


}
