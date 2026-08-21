<?php

namespace App\Http\Controllers\Api\Restaurante;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;

use App\Models\Pedido;
use App\Models\PedidoDetalle;
use App\Models\Cliente;
use Illuminate\Support\Facades\DB;

class PedidoController extends Controller
{
    private function generateEan13()
    {
        // Internal EAN-13 (starts with 20-29 range naturally with year 2020-2029)
        $base = date('ymdHis'); // 12 digits
        $sum = 0;
        for ($i = 0; $i < 12; $i++) {
            $sum += (int)$base[$i] * ($i % 2 === 0 ? 1 : 3);
        }
        $checkDigit = (10 - ($sum % 10)) % 10;
        return $base . $checkDigit;
    }

    // GET /api/pedidos
    public function index(Request $request)
    {
        $fecha = $request->query('fecha', date('Y-m-d'));
        $pedidos = Pedido::with('detalles')->where('fecha', $fecha)->orderBy('secuencia_diaria', 'asc')->get();
        return response()->json(['success' => true, 'data' => $pedidos]);
    }

    // GET /api/pedidos/codigo/{codigo}
    public function getByCodigo($codigo)
    {
        $pedido = Pedido::with('detalles')->where('codigo_barras', $codigo)->first();
        if (!$pedido) {
            return response()->json(['success' => false, 'message' => 'Pedido no encontrado'], 404);
        }
        return response()->json(['success' => true, 'pedido' => $pedido]);
    }

    // POST /api/pedidos
    public function store(Request $request)
    {
        $request->validate([
            'cliente_nombre' => 'required|string',
            'cliente_telefono' => 'nullable|string',
            'direccion' => 'nullable|string',
            'tipo_entrega' => 'required|string',
            'nota' => 'nullable|string',
            'detalles' => 'required|array|min:1',
            'detalles.*.producto_id' => 'required|exists:productos,id',
            'detalles.*.cantidad' => 'required|numeric|min:1',
            'detalles.*.precio_unitario' => 'required|numeric|min:0',
        ]);

        DB::beginTransaction();
        try {
            $telefono = $request->input('cliente_telefono') ?: 'N/A';
            $direccion = $request->input('direccion') ?: 'N/A';
            $nota = $request->input('nota') ?: 'Sin notas';
            
            $fecha = $request->input('fecha') ?? date('Y-m-d');
            $maxSecuencia = Pedido::where('fecha', $fecha)->max('secuencia_diaria');
            $secuencia = $maxSecuencia ? $maxSecuencia + 1 : 1;

            $total = $request->input('total') ?? 0;

            $pedido = Pedido::create([
                'secuencia_diaria' => $secuencia,
                'fecha' => $fecha,
                'cliente_nombre' => $request->input('cliente_nombre'),
                'cliente_telefono' => $telefono,
                'direccion' => $direccion,
                'tipo_entrega' => $request->input('tipo_entrega') === 'Delivery' ? 'Domicilio' : $request->input('tipo_entrega'),
                'estado' => 'Pendiente',
                'nota' => $nota,
                'total' => $total,
                'codigo_barras' => $this->generateEan13(),
            ]);

            foreach ($request->input('detalles') as $det) {
                // Obtener nombre del producto si no viene en el payload
                $producto = DB::table('productos')->where('id', $det['producto_id'])->first();
                $nombreProducto = $producto ? $producto->nombre : 'Desconocido';

                PedidoDetalle::create([
                    'pedido_id' => $pedido->id,
                    'producto_id' => $det['producto_id'],
                    'nombre_producto' => $det['nombre_producto'] ?? $nombreProducto,
                    'cantidad' => $det['cantidad'],
                    'precio_unitario' => $det['precio_unitario'],
                    'subtotal' => $det['cantidad'] * $det['precio_unitario'],
                ]);
            }

            DB::commit();
            return response()->json([
                'success' => true,
                'message' => 'Pedido registrado exitosamente',
                'pedido' => $pedido->load('detalles'),
            ], 201);
        } catch (\Exception $e) {
            DB::rollBack();
            return response()->json(['success' => false, 'message' => $e->getMessage()], 500);
        }
    }

    // POST /api/pedidos/bot
    public function storeWebhook(Request $request)
    {
        $request->validate([
            'cliente_nombre' => 'required|string',
            'cliente_telefono' => 'required|string',
            'direccion' => 'nullable|string',
            'tipo_entrega' => 'required|in:Domicilio,Recoger,Local',
            'nota' => 'nullable|string',
            'detalles' => 'required|array|min:1',
            'detalles.*.producto_id' => 'required|exists:productos,id',
            'detalles.*.nombre_producto' => 'required|string',
            'detalles.*.cantidad' => 'required|numeric|min:1',
            'detalles.*.precio_unitario' => 'required|numeric|min:0',
        ]);

        DB::beginTransaction();
        try {
            // Find or Create Client
            $telefono = $request->input('cliente_telefono');
            $cliente = Cliente::where('telefono', $telefono)->orWhere('celular', $telefono)->first();
            if (!$cliente) {
                $cliente = Cliente::create([
                    'nombre' => $request->input('cliente_nombre'),
                    'telefono' => $telefono,
                    'direccion' => $request->input('direccion'),
                ]);
            }

            $fecha = date('Y-m-d');
            $maxSecuencia = Pedido::where('fecha', $fecha)->max('secuencia_diaria');
            $secuencia = $maxSecuencia ? $maxSecuencia + 1 : 1;

            $total = 0;
            foreach ($request->input('detalles') as $det) {
                $total += $det['cantidad'] * $det['precio_unitario'];
            }

            $pedido = Pedido::create([
                'secuencia_diaria' => $secuencia,
                'fecha' => $fecha,
                'cliente_nombre' => $cliente->nombre,
                'cliente_telefono' => $telefono,
                'direccion' => $request->input('direccion') ?? $cliente->direccion,
                'tipo_entrega' => $request->input('tipo_entrega'),
                'estado' => 'Pendiente',
                'nota' => $request->input('nota'),
                'total' => $total,
                'codigo_barras' => $this->generateEan13(),
            ]);

            foreach ($request->input('detalles') as $det) {
                PedidoDetalle::create([
                    'pedido_id' => $pedido->id,
                    'producto_id' => $det['producto_id'],
                    'nombre_producto' => $det['nombre_producto'],
                    'cantidad' => $det['cantidad'],
                    'precio_unitario' => $det['precio_unitario'],
                    'subtotal' => $det['cantidad'] * $det['precio_unitario'],
                ]);
            }

            DB::commit();
            return response()->json([
                'success' => true,
                'message' => 'Pedido registrado exitosamente',
                'pedido' => $pedido->load('detalles'),
            ], 201);
        } catch (\Exception $e) {
            DB::rollBack();
            return response()->json(['success' => false, 'message' => $e->getMessage()], 500);
        }
    }

    // PUT /api/pedidos/{id}/estado
    public function updateStatus(Request $request, $id)
    {
        $request->validate(['estado' => 'required|in:Pendiente,Confirmado,Preparando,Facturado,Cancelado']);
        $pedido = Pedido::findOrFail($id);
        $pedido->estado = $request->estado;
        $pedido->save();
        return response()->json(['success' => true, 'pedido' => $pedido]);
    }
}

