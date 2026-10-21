<?php

namespace App\Http\Controllers\Api\Facturacion;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Factura;
use App\Models\NotaCredito;
use App\Models\NotaCreditoDetalle;
use App\Models\Producto;
use App\Models\MovimientoInventario;
use App\Modules\Contabilidad\Services\ContabilidadService;
use Illuminate\Support\Facades\DB;
use App\Traits\HasIdempotency;
use Barryvdh\DomPDF\Facade\Pdf;
use App\Models\Pago;
use App\Modules\Caja\Services\CajaService;

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

            $factura = Factura::with(['detalles.producto', 'cliente'])->findOrFail($facturaId);

            if (strtoupper($factura->estado) === 'ANULADA') {
                throw new \Exception("No se puede emitir una Nota de Crédito sobre una factura que ya está anulada.");
            }

            // Determinar si la factura original es electrónica (e-CF) o tradicional
            $esElectronica = str_starts_with(strtoupper($factura->ncf ?? ''), 'E');
            $tipoSecuencia = $esElectronica ? '34' : '04';
            $padLength = $esElectronica ? 10 : 8;

            $secuencia = DB::table('ncf_secuencias')
                ->where('tipo', $tipoSecuencia)
                ->lockForUpdate()
                ->first();

            if (!$secuencia) {
                // Si no existe B04 tradicional, intentar con tipo 4
                $secuencia = DB::table('ncf_secuencias')
                    ->where('tipo', (string)(int)$tipoSecuencia)
                    ->lockForUpdate()
                    ->first();
            }

            if (!$secuencia) {
                $nombreDoc = $esElectronica ? "Nota de Crédito Electrónica (E34)" : "Nota de Crédito (B04)";
                throw new \Exception("Secuencia NCF para {$nombreDoc} no configurada.");
            }

            $nuevoActual = $secuencia->actual + 1;
            $ncf = $secuencia->prefijo . str_pad((string)$secuencia->tipo, 2, '0', STR_PAD_LEFT) . str_pad((string)$nuevoActual, $padLength, '0', STR_PAD_LEFT);
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

                // Validar acumulado previamente devuelto para no devolver de más
                $yaDevuelto = (float) NotaCreditoDetalle::whereHas('notaCredito', function ($q) use ($factura) {
                    $q->where('factura_id', $factura->id);
                })->where('producto_id', $det['producto_id'])->sum('cantidad');

                $disponible = round((float)$detalleFactura->cantidad - $yaDevuelto, 2);
                if ($det['cantidad'] > ($disponible + 0.001)) {
                    $nomProd = $detalleFactura->producto->nombre ?? "Producto #{$det['producto_id']}";
                    throw new \Exception("No puedes devolver {$det['cantidad']} unidades de '{$nomProd}'. Cantidad disponible: {$disponible} (facturado: {$detalleFactura->cantidad}, devuelto anteriormente: {$yaDevuelto}).");
                }

                $precioUnitario = (float) $detalleFactura->precio;
                $proporcion = (float) $det['cantidad'] / (float) $detalleFactura->cantidad;
                $total = round((float)$detalleFactura->total * $proporcion, 2);
                $itbis = round((float)$detalleFactura->itbis * $proporcion, 2);
                $subtotal = round($total - $itbis, 2);

                NotaCreditoDetalle::create([
                    'nota_credito_id' => $notaCredito->id,
                    'producto_id'     => $det['producto_id'],
                    'cantidad'        => $det['cantidad'],
                    'precio_unitario' => $precioUnitario,
                    'subtotal'        => $subtotal,
                    'itbis'           => $itbis,
                    'total'           => $total,
                ]);

                // Retornar al inventario si maneja stock y no es un servicio
                $producto = Producto::find($det['producto_id']);
                if ($producto && $producto->tipo_producto !== 'SERVICIO' && $producto->maneja_inventario) {
                    $producto->stock_actual += $det['cantidad'];
                    $producto->save();

                    MovimientoInventario::create([
                        'producto_id' => $producto->id,
                        'tipo'        => 'ENTRADA',
                        'cantidad'    => $det['cantidad'],
                        'referencia'  => "NOTA DE CRÉDITO: " . $ncf . " (Factura #{$factura->id})",
                        'fecha'       => now(),
                    ]);

                    $costoUnitario = (float) ($producto->costo ?? 0);
                    $costoTotal += ($costoUnitario * (float) $det['cantidad']);
                }

                $subtotalTotal += $subtotal;
                $itbisTotal += $itbis;
                $totalMonto += $total;
            }

            // Actualizar montos definitivos de la nota de crédito
            $notaCredito->update([
                'subtotal' => round($subtotalTotal, 2),
                'itbis'    => round($itbisTotal, 2),
                'total'    => round($totalMonto, 2),
            ]);

            // Determinar si la factura tiene deuda pendiente en cuentas por cobrar
            $cxc = \App\Models\CuentaPorCobrar::where('factura_id', $factura->id)->first();
            $esFacturaCredito = $cxc && (float)$cxc->balance_pendiente > 0;

            // 1. Motor Contable Automático (Partida Doble)
            $contabilidadService = app(ContabilidadService::class);
            $asiento = $contabilidadService->registrarAsientoAuto(
                new \App\Modules\Contabilidad\DTOs\RegistrarAsientoDTO(
                    'devolucion_venta',
                    round($subtotalTotal, 2),
                    round($itbisTotal, 2),
                    round($totalMonto, 2),
                    "NotaCredito-{$notaCredito->id}",
                    "Nota de Crédito NCF: {$ncf} (Afecta Factura #{$factura->id} - {$factura->ncf})",
                    auth()->id(),
                    [
                        'es_credito' => $esFacturaCredito,
                    ],
                    round($costoTotal, 2)
                )
            );

            // 2. Si la venta tenía balance pendiente a crédito, rebajar la Cuenta por Cobrar (CxC)
            if ($esFacturaCredito && $cxc) {
                $nuevoBalance = max(0, round((float)$cxc->balance_pendiente - $totalMonto, 2));
                $cxc->balance_pendiente = $nuevoBalance;
                if ($nuevoBalance <= 0.01) {
                    $cxc->estado = 'PAGADA';
                }
                $cxc->save();
            } else {
                // 3. Si la venta fue al contado y se pagó en efectivo, registrar devolución de caja
                $pagoOriginalEfectivo = Pago::where('factura_id', $factura->id)
                    ->where('metodo_pago', 'efectivo')
                    ->first();

                if ($pagoOriginalEfectivo) {
                    $cajaService = app(CajaService::class);
                    $sesionActiva = $cajaService->getSesionActiva(auth()->id());

                    if ($sesionActiva) {
                        Pago::create([
                            'factura_id'      => $factura->id,
                            'user_id'         => auth()->id(),
                            'caja_sesion_id'  => $sesionActiva->id,
                            'monto_pagado'    => -round($totalMonto, 2),
                            'monto_recibido'  => -round($totalMonto, 2),
                            'devuelta'        => 0,
                            'metodo_pago'     => 'efectivo',
                            'referencia_pago' => 'Devolución NCF: ' . $ncf,
                            'fecha_pago'      => now(),
                        ]);
                    }
                }
            }

            DB::commit();

            $pdfUrl = \App\Services\DocumentoSeguroService::generarUrlTemporal('nota_credito', $notaCredito->id, 15);

            return response()->json([
                'message'    => 'Nota de Crédito generada exitosamente.',
                'data'       => $notaCredito->load(['detalles.producto', 'factura.cliente']),
                'asiento_id' => $asiento?->id,
                'pdf_url'    => $pdfUrl,
            ], 201);

        } catch (\Exception $e) {
            DB::rollBack();
            return response()->json(['error' => $e->getMessage()], 500);
        }
    }

    /**
     * Retorna la URL temporal encriptada para visualizar el PDF de la Nota de Crédito.
     */
    public function pdfUrl($id)
    {
        $notaCredito = NotaCredito::findOrFail($id);
        $url = \App\Services\DocumentoSeguroService::generarUrlTemporal('nota_credito', (int)$notaCredito->id, 15);

        return response()->json([
            'success' => true,
            'url'     => $url,
            'expira_en_minutos' => 15,
        ]);
    }

    public function pdf($id)
    {
        $token = request()->query('token');

        // 1. Probar si es un token temporal encriptado
        if ($token) {
            try {
                $datos = \App\Services\DocumentoSeguroService::validarYObtenerDatos($token);
                if ((int)$datos['id'] === (int)$id && $datos['tipo'] === 'nota_credito') {
                    return $this->generarPdfStream((int)$id);
                }
            } catch (\Exception $e) {
                // Continuar a verificar si es Sanctum
            }
        }

        // 2. Fallback a token Sanctum para retrocompatibilidad
        if ($token && \Laravel\Sanctum\PersonalAccessToken::findToken($token)) {
            return $this->generarPdfStream((int)$id);
        }

        abort(403, 'Enlace no autorizado o expirado.');
    }

    private function generarPdfStream(int $id)
    {
        $notaCredito = NotaCredito::with(['detalles.producto', 'factura.cliente', 'factura.user'])->findOrFail($id);
        $pdf = Pdf::loadView('pdf.nota_credito', compact('notaCredito'));
        return $pdf->stream('nota_credito_' . $notaCredito->id . '.pdf');
    }
}

