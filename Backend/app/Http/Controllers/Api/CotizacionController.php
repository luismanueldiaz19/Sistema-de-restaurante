<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Cotizacion;
use App\Models\CotizacionDetalle;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Validator;
use Barryvdh\DomPDF\Facade\Pdf;
use Exception;

class CotizacionController extends Controller
{
    public function store(Request $request)
    {
        DB::beginTransaction();

        try {
            $validator = Validator::make($request->all(), [
                'cliente_id' => 'required|exists:clientes,id',
                'fecha_emision' => 'required|date',
                'detalles' => 'required|array|min:1',
            ]);

            if ($validator->fails()) {
                return response()->json([
                    'message' => 'Error en la validación',
                    'errors' => $validator->errors(),
                    'status' => 400
                ], 400);
            }

            $detalles = $request->detalles;

            $subtotal = 0;
            $itbisTotal = 0;
            $descuentoTotal = 0;

            $detallesCalculados = [];

            foreach ($detalles as $item) {
                $calc = $this->calcularLinea($item);

                $subtotal += $calc['baseConDescuento'];
                $descuentoTotal += $calc['descuento'];
                $itbisTotal += $calc['itbis'];

                $detallesCalculados[] = [
                    'item' => $item,
                    'calc' => $calc
                ];
            }

            $total = $subtotal + $itbisTotal;

            // Fecha de vencimiento (por defecto 15 días si no se provee)
            $fechaVencimiento = $request->fecha_vencimiento ?? date('Y-m-d', strtotime($request->fecha_emision . ' + 15 days'));

            $cotizacion_id = DB::table('cotizaciones')->insertGetId([
                'user_id' => auth()->id(),
                'cliente_id' => $request->cliente_id,
                'fecha_emision' => $request->fecha_emision,
                'fecha_vencimiento' => $fechaVencimiento,
                'subtotal' => round($subtotal, 2),
                'descuento_total' => round($descuentoTotal, 2),
                'itbis' => round($itbisTotal, 2),
                'total' => round($total, 2),
                'estado' => 'aprobado', // o pendiente, según el flujo.
                'nota' => $request->nota,
                'created_at' => now(),
                'updated_at' => now(),
            ]);

            foreach ($detallesCalculados as $detalle) {
                $item = $detalle['item'];
                $calc = $detalle['calc'];

                DB::table('cotizacion_detalles')->insert([
                    'cotizacion_id' => $cotizacion_id,
                    'producto_id' => $item['producto_id'] ?? null,
                    'descripcion' => $item['descripcion'],
                    'cantidad' => $item['cantidad'],
                    'precio' => $item['precio'],
                    'itbis' => round($calc['itbis'], 2),
                    'total' => round($calc['total'], 2),
                    'created_at' => now(),
                    'updated_at' => now(),
                ]);
            }

            DB::commit();

            $token = \Illuminate\Support\Str::random(40);
            \Illuminate\Support\Facades\Cache::put("cotizacion_pdf_{$cotizacion_id}_{$token}", [
                'company_name' => $request->company_name,
                'company_rnc' => $request->company_rnc,
                'company_address' => $request->company_address,
                'company_phone' => $request->company_phone,
            ], now()->addHours(24));

            $pdf_url = "/api/cotizaciones/{$cotizacion_id}/pdf?token={$token}";

            return response()->json([
                'message' => 'Cotización creada correctamente',
                'status' => 201,
                'cotizacion_id' => $cotizacion_id,
                'pdf_url' => $pdf_url
            ], 201);

        } catch (\Exception $e) {
            DB::rollBack();

            return response()->json([
                'message' => 'Error al crear la cotización',
                'error' => $e->getMessage(),
                'status' => 500
            ], 500);
        }
    }

    public function index(Request $request)
    {
        $query = Cotizacion::with('cliente', 'user')
            ->orderBy('fecha_emision', 'desc');

        if ($request->filled('fecha_desde')) {
            $query->where('fecha_emision', '>=', $request->fecha_desde);
        }

        if ($request->filled('fecha_hasta')) {
            $query->where('fecha_emision', '<=', $request->fecha_hasta . ' 23:59:59');
        }

        if ($request->filled('cliente_id')) {
            $query->where('cliente_id', $request->cliente_id);
        }

        if ($request->filled('estado')) {
            $query->where('estado', $request->estado);
        }

        $resumenQuery = clone $query;
        $totales = $resumenQuery->reorder()->selectRaw('
            COUNT(*) as cantidad_cotizaciones, 
            SUM(total) as total_monto
        ')->first();

        $cotizaciones = $query->paginate($request->per_page ?? 15);

        $cotizaciones->getCollection()->transform(function ($cotizacion) use ($request) {
            $token = \Illuminate\Support\Str::random(40);
            \Illuminate\Support\Facades\Cache::put("cotizacion_pdf_{$cotizacion->id}_{$token}", [
                'company_name' => $request->company_name,
                'company_rnc' => $request->company_rnc,
                'company_address' => $request->company_address,
                'company_phone' => $request->company_phone,
            ], now()->addHours(24));

            $cotizacion->pdf_url = "/api/cotizaciones/{$cotizacion->id}/pdf?token={$token}";
            return $cotizacion;
        });

        return response()->json([
            'status' => true,
            'data'   => $cotizaciones,
            'resumen' => $totales
        ]);
    }

    public function show(Request $request, $id)
    {
        try {
            $cotizacion = Cotizacion::with([
                'cliente',
                'detalles',
                'user'
            ])->find($id);

            if (!$cotizacion) {
                return response()->json([
                    'message' => 'Cotización no encontrada',
                    'status' => 404
                ], 404);
            }

            $token = \Illuminate\Support\Str::random(40);
            \Illuminate\Support\Facades\Cache::put("cotizacion_pdf_{$cotizacion->id}_{$token}", [
                'company_name' => $request->company_name,
                'company_rnc' => $request->company_rnc,
                'company_address' => $request->company_address,
                'company_phone' => $request->company_phone,
            ], now()->addHours(24));

            $cotizacion->pdf_url = "/api/cotizaciones/{$cotizacion->id}/pdf?token={$token}";

            return response()->json([
                'message' => 'Cotización encontrada',
                'status' => 200,
                'data' => $cotizacion
            ], 200);

        } catch (\Exception $e) {
            return response()->json([
                'message' => 'Error al obtener la cotización',
                'error' => $e->getMessage(),
                'status' => 500
            ], 500);
        }
    }

    public function updateStatus(Request $request, $id)
    {
        $request->validate([
            'estado' => 'required|in:aprobado,cancelado,pendiente'
        ]);

        $cotizacion = Cotizacion::find($id);
        if (!$cotizacion) {
            return response()->json(['message' => 'No encontrada'], 404);
        }

        $cotizacion->estado = $request->estado;
        $cotizacion->save();

        return response()->json([
            'status' => true,
            'message' => 'Estado actualizado a ' . $request->estado
        ]);
    }

    public function pdf(Request $request, $id)
    {
        $token = $request->query('token');
        if (!$token) {
            abort(403, 'Acceso denegado: Token de seguridad no proporcionado.');
        }

        $companyData = \Illuminate\Support\Facades\Cache::get("cotizacion_pdf_{$id}_{$token}");
        
        if (!$companyData) {
            abort(403, 'Acceso denegado: El enlace ha expirado o es inválido.');
        }

        $cotizacion = Cotizacion::with(['cliente', 'detalles', 'user'])->findOrFail($id);

        $company = [
            'nombre' => $companyData['company_name'] ?? 'Tu Restaurante Favorito',
            'rnc' => $companyData['company_rnc'] ?? '123456789',
            'direccion' => $companyData['company_address'] ?? 'Santo Domingo, República Dominicana',
            'telefono' => $companyData['company_phone'] ?? '(809) 555-5555',
        ];

        // Se usa view para renderizar el blade y luego generar el pdf.
        $pdf = Pdf::loadView('pdf.cotizacion', compact('cotizacion', 'company'));

        return $pdf->stream('cotizacion_'.$cotizacion->id.'.pdf');
    }

    private function calcularLinea($item)
    {
        $cantidad = $item['cantidad'];
        $precio = $item['precio'];
        $itbisPct = isset($item['itbis_porcentaje']) ? (float) $item['itbis_porcentaje'] : 18.0;
        $divisor = 1 + ($itbisPct / 100); // 1.18 si 18%, 1.0 si 0%

        $linea = $cantidad * $precio;

        // Extraemos la base imponible del precio (que ya incluye ITBIS)
        $base = $divisor > 1 ? $linea / $divisor : $linea;

        $descuento = $item['descuento'] ?? 0;
        if (!empty($item['descuento_porcentaje'])) {
            $descuento = $base * ($item['descuento_porcentaje'] / 100);
        }

        $baseConDescuento = $base - $descuento;
        $itbis = $baseConDescuento * ($itbisPct / 100);
        $total = $baseConDescuento + $itbis;

        return [
            'base' => $base,
            'descuento' => $descuento,
            'baseConDescuento' => $baseConDescuento,
            'itbis' => $itbis,
            'total' => $total
        ];
    }
}
