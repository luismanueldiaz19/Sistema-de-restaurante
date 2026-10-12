<?php

declare(strict_types=1);

namespace App\Modules\Pedido\Services;

use App\Modules\Pedido\DTOs\CreatePedidoDTO;
use App\Modules\Pedido\Exceptions\PedidoException;
use App\Models\Pedido;
use App\Models\PedidoDetalle;
use App\Models\Cliente;
use App\Models\Producto;
use Illuminate\Database\Eloquent\Collection;
use Illuminate\Support\Facades\DB;

class PedidoService
{
    public function generateEan13(): string
    {
        // Internal EAN-13 (empieza en rango 20-29 naturalmente con el año 2020-2029)
        $base = date('ymdHis'); // 12 dígitos
        $sum = 0;
        for ($i = 0; $i < 12; $i++) {
            $sum += (int) $base[$i] * ($i % 2 === 0 ? 1 : 3);
        }
        $checkDigit = (10 - ($sum % 10)) % 10;
        return $base . $checkDigit;
    }

    public function getByDate(string $fecha): Collection
    {
        return Pedido::with('detalles')
            ->where('fecha', $fecha)
            ->orderBy('secuencia_diaria', 'asc')
            ->get();
    }

    public function getByCodigo(string $codigo): ?Pedido
    {
        return Pedido::with('detalles')
            ->where('codigo_barras', $codigo)
            ->first();
    }

    public function findById(int $id): ?Pedido
    {
        return Pedido::with(['detalles.producto', 'factura'])->find($id);
    }

    public function create(CreatePedidoDTO $dto): Pedido
    {
        return DB::transaction(function () use ($dto) {
            $telefono = !empty($dto->clienteTelefono) ? $dto->clienteTelefono : 'N/A';
            $direccion = !empty($dto->direccion) ? $dto->direccion : 'N/A';
            $nota = !empty($dto->nota) ? $dto->nota : 'Sin notas';

            $fecha = !empty($dto->fecha) ? $dto->fecha : date('Y-m-d');
            $maxSecuencia = Pedido::where('fecha', $fecha)->max('secuencia_diaria');
            $secuencia = $maxSecuencia ? $maxSecuencia + 1 : 1;

            $total = $dto->total;
            if ($total <= 0) {
                foreach ($dto->detalles as $det) {
                    $total += ((float) $det['cantidad']) * ((float) $det['precio_unitario']);
                }
            }

            $pedido = Pedido::create([
                'secuencia_diaria' => $secuencia,
                'fecha'            => $fecha,
                'cliente_nombre'   => $dto->clienteNombre,
                'cliente_telefono' => $telefono,
                'direccion'        => $direccion,
                'tipo_entrega'     => $dto->tipoEntrega,
                'estado'           => 'Pendiente',
                'nota'             => $nota,
                'total'            => round($total, 2),
                'codigo_barras'    => $this->generateEan13(),
            ]);

            foreach ($dto->detalles as $det) {
                $nombreProducto = $det['nombre_producto'] ?? null;
                if (empty($nombreProducto)) {
                    $producto = Producto::find($det['producto_id']);
                    $nombreProducto = $producto ? $producto->nombre : 'Desconocido';
                }

                $cantidad = (float) $det['cantidad'];
                $precioUnitario = (float) $det['precio_unitario'];

                PedidoDetalle::create([
                    'pedido_id'       => $pedido->id,
                    'producto_id'     => (int) $det['producto_id'],
                    'nombre_producto' => $nombreProducto,
                    'cantidad'        => $cantidad,
                    'precio_unitario' => $precioUnitario,
                    'subtotal'        => round($cantidad * $precioUnitario, 2),
                ]);
            }

            return $pedido->load('detalles');
        });
    }

    public function createFromWebhook(array $data): Pedido
    {
        return DB::transaction(function () use ($data) {
            $telefono = $data['cliente_telefono'] ?? 'N/A';
            $cliente = Cliente::where('telefono', $telefono)->orWhere('celular', $telefono)->first();
            if (!$cliente) {
                $cliente = Cliente::create([
                    'nombre'    => $data['cliente_nombre'],
                    'telefono'  => $telefono,
                    'direccion' => $data['direccion'] ?? null,
                ]);
            }

            $fecha = date('Y-m-d');
            $maxSecuencia = Pedido::where('fecha', $fecha)->max('secuencia_diaria');
            $secuencia = $maxSecuencia ? $maxSecuencia + 1 : 1;

            $total = 0;
            foreach ($data['detalles'] as $det) {
                $total += ((float) $det['cantidad']) * ((float) $det['precio_unitario']);
            }

            $pedido = Pedido::create([
                'secuencia_diaria' => $secuencia,
                'fecha'            => $fecha,
                'cliente_nombre'   => $cliente->nombre,
                'cliente_telefono' => $telefono,
                'direccion'        => $data['direccion'] ?? $cliente->direccion ?? 'N/A',
                'tipo_entrega'     => $data['tipo_entrega'],
                'estado'           => 'Pendiente',
                'nota'             => $data['nota'] ?? 'Sin notas',
                'total'            => round($total, 2),
                'codigo_barras'    => $this->generateEan13(),
            ]);

            foreach ($data['detalles'] as $det) {
                $cantidad = (float) $det['cantidad'];
                $precioUnitario = (float) $det['precio_unitario'];

                PedidoDetalle::create([
                    'pedido_id'       => $pedido->id,
                    'producto_id'     => (int) $det['producto_id'],
                    'nombre_producto' => $det['nombre_producto'],
                    'cantidad'        => $cantidad,
                    'precio_unitario' => $precioUnitario,
                    'subtotal'        => round($cantidad * $precioUnitario, 2),
                ]);
            }

            return $pedido->load('detalles');
        });
    }

    public function updateStatus(int $id, string $estado): Pedido
    {
        $pedido = Pedido::findOrFail($id);
        $pedido->estado = $estado;
        $pedido->save();

        return $pedido->load('detalles');
    }
}
