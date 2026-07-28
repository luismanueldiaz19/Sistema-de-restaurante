<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Factura;
use App\Models\NotaCredito;
use App\Models\NotaCreditoDetalle;
use App\Models\Producto;
use App\Services\ContabilidadService;
use Illuminate\Support\Facades\DB;
use App\Traits\HasIdempotency;
use Barryvdh\DomPDF\Facade\Pdf;
use App\Models\Pago;
use App\Services\CajaService;

class NotaCreditoController extends Controller
{
    use HasIdempotency;

    public function index(Request $request)
    {
        $query = NotaCredito::with(['factura.cliente', 'detalles.producto']);

        if ($request->filled('search')) {
            $searchTerm = $request->search;
            $query->where(function ($q) use ($searchTerm) {
                $q->where('id', 'like', "%{$searchTerm}%")
                  ->orWhere('ncf', 'like', "%{$searchTerm}%")
                  ->orWhereHas('factura.cliente', function ($q2) use ($searchTerm) {
                      $q2->where('nombre', 'like', "%{$searchTerm}%");
                  });
            });
        }

        if ($request->filled('fecha_desde')) {
            $query->whereDate('created_at', '>=', $request->fecha_desde);
        }

        if ($request->filled('fecha_hasta')) {
            $query->whereDate('created_at', '<=', $request->fecha_hasta);
        }

        $resumenQuery = clone $query;
        $totales = $resumenQuery->selectRaw('
            COUNT(*) as cantidad_notas,
            SUM(total) as total_monto
        ')->first();

        $notas = $query->orderBy('created_at', 'desc')->paginate($request->per_page ?? 15);

        return response()->json([
            'status' => true,
            'data'   => $notas,
            'resumen' => [
                'totales' => $totales
            ]
        ]);
    }

    public function store(Request $request, $facturaId)
    {
        $request->validate([
            'detalles' => 'required|array|min:1',
            'detalles.*.producto_id' => 'required|exists:productos,id',
            'detalles.*.cantidad' => 'required|numeric|min:0.01',
            'motivo' => 'required|string',
        ]);

        try {
            DB::beginTransaction();

            $factura = Factura::with('detalles')->findOrFail($facturaId);

            // Obtener NCF E34
            $secuencia = DB::table('ncf_secuencias')->where('tipo', '34')->lockForUpdate()->first();
            if (!$secuencia) {
                throw new \Exception("Secuencia para Nota de Crédito (34) no configurada.");
            }
            $nuevoActual = $secuencia->actual + 1;
            $ncf = $secuencia->prefijo . str_pad($secuencia->tipo, 2, '0', STR_PAD_LEFT) . str_pad($nuevoActual, 8, '0', STR_PAD_LEFT);
            DB::table('ncf_secuencias')->where('id', $secuencia->id)->update(['actual' => $nuevoActual]);

            $subtotalTotal = 0;
            $itbisTotal = 0;
            $totalMonto = 0;
            $costoTotal = 0;

            $notaCredito = NotaCredito::create([
                'factura_id' => $factura->id,
                'user_id' => auth()->id(),
                'ncf' => $ncf,
                'subtotal' => 0,
                'itbis' => 0,
                'total' => 0,
                'motivo' => $request->motivo,
            ]);

            foreach ($request->detalles as $det) {
                // Verificar que el producto exista en la factura original
                $detalleFactura = $factura->detalles->where('producto_id', $det['producto_id'])->first();
                if (!$detalleFactura) {
                    throw new \Exception("El producto ID {$det['producto_id']} no pertenece a esta factura.");
                }

                // Verificar que no devuelva más de lo facturado
                if ($det['cantidad'] > $detalleFactura->cantidad) {
                    throw new \Exception("No puedes devolver más cantidad de la facturada original.");
                }

                $precioUnitario = $detalleFactura->precio;
                
                // Calculamos proporcionales al total real de la linea
                $proporcion = $det['cantidad'] / $detalleFactura->cantidad;
                $total = round($detalleFactura->total * $proporcion, 2);
                $itbis = round($detalleFactura->itbis * $proporcion, 2);
                $subtotal = $total - $itbis;

                NotaCreditoDetalle::create([
                    'nota_credito_id' => $notaCredito->id,
                    'producto_id' => $det['producto_id'],
                    'cantidad' => $det['cantidad'],
                    'precio_unitario' => $precioUnitario,
                    'subtotal' => round($subtotal, 2),
                    'itbis' => round($itbis, 2),
                    'total' => round($total, 2),
                ]);

                // Retornar al inventario
                $producto = Producto::find($det['producto_id']);
                if ($producto && $producto->tipo_producto != 'SERVICIO') {
                    $producto->stock_actual += $det['cantidad'];
                    $producto->save();

                    $costoUnitario = $producto->costo_promedio > 0 ? $producto->costo_promedio : $producto->ultimo_costo;
                    $costoTotal += ($costoUnitario * $det['cantidad']);
                }

                $subtotalTotal += $subtotal;
                $itbisTotal += $itbis;
                $totalMonto += $total;
            }

            // Actualizar nota de credito
            $notaCredito->update([
                'subtotal' => round($subtotalTotal, 2),
                'itbis' => round($itbisTotal, 2),
                'total' => round($totalMonto, 2),
            ]);

            // Generar asiento contable automático
            $contabilidadService = new ContabilidadService();
            $contabilidadService->registrarAsientoAuto(
                'devolucion_venta',
                round($subtotalTotal, 2),
                round($itbisTotal, 2),
                round($totalMonto, 2),
                "NotaCredito-{$notaCredito->id}",
                "Devolución parcial de Venta, NCF: {$ncf}",
                auth()->id(),
                [],
                round($costoTotal, 2)
            );

            // Restar de la caja actual si la factura original se pagó en efectivo
            $pagoOriginalEfectivo = Pago::where('factura_id', $factura->id)
                ->where('metodo_pago', 'efectivo')
                ->first();

            if ($pagoOriginalEfectivo) {
                $cajaService = new CajaService();
                $sesionActiva = $cajaService->getSesionActiva(auth()->id());

                if ($sesionActiva) {
                    Pago::create([
                        'factura_id' => $factura->id,
                        'user_id' => auth()->id(),
                        'caja_sesion_id' => $sesionActiva->id,
                        'monto_pagado' => -round($totalMonto, 2),
                        'monto_recibido' => -round($totalMonto, 2),
                        'devuelta' => 0,
                        'metodo_pago' => 'efectivo',
                        'referencia_pago' => 'Devolución NCF: ' . $ncf,
                        'fecha_pago' => now(),
                    ]);
                }
            }

            DB::commit();

            return response()->json([
                'message' => 'Nota de Crédito generada exitosamente.',
                'data' => $notaCredito->load('detalles.producto'),
            ], 201);

        } catch (\Exception $e) {
            DB::rollBack();
            return response()->json(['error' => $e->getMessage()], 500);
        }
    }

    public function pdf($id)
    {
        $token = request()->query('token');
        if (!$token || !\Laravel\Sanctum\PersonalAccessToken::findToken($token)) {
            abort(403, 'USER IS NOT LOGGED IN.');
        }

        $notaCredito = NotaCredito::with(['detalles.producto', 'factura.cliente', 'factura.user'])->findOrFail($id);

        $pdf = Pdf::loadView('pdf.nota_credito', compact('notaCredito'));

        return $pdf->stream('nota_credito_' . $notaCredito->id . '.pdf');
    }
}
