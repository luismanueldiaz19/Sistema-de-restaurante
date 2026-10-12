<?php

declare(strict_types=1);

namespace App\Modules\Mesa\Services;

use App\Models\Pedido;
use App\Models\PedidoDetalle;
use App\Modules\Mesa\DTOs\AbrirMesaDTO;
use App\Modules\Mesa\DTOs\AgregarItemsMesaDTO;
use App\Modules\Mesa\DTOs\CreateMesaDTO;
use App\Modules\Mesa\DTOs\UpdateMesaDTO;
use App\Modules\Mesa\Models\Mesa;
use App\Modules\Pedido\Services\PedidoService;
use Exception;
use Illuminate\Database\Eloquent\Collection;
use Illuminate\Support\Facades\DB;

class MesaService
{
    public function __construct(
        private readonly PedidoService $pedidoService
    ) {}

    public function getAll(?string $area = null): Collection
    {
        $query = Mesa::with(['ordenActiva.detalles']);

        if ($area && $area !== 'Todas') {
            $query->where('area', $area);
        }

        $mesas = $query->get();

        return $mesas->sort(function (Mesa $a, Mesa $b) {
            preg_match('/\d+/', $a->nombre, $matchesA);
            preg_match('/\d+/', $b->nombre, $matchesB);

            $numA = isset($matchesA[0]) ? (int) $matchesA[0] : null;
            $numB = isset($matchesB[0]) ? (int) $matchesB[0] : null;

            if ($numA !== null && $numB !== null && $numA !== $numB) {
                return $numA <=> $numB;
            }

            return strnatcasecmp($a->nombre, $b->nombre);
        })->values();
    }

    public function findById(int $id): ?Mesa
    {
        return Mesa::with(['ordenActiva.detalles'])->find($id);
    }

    public function create(CreateMesaDTO $dto): Mesa
    {
        return Mesa::create($dto->toArray());
    }

    public function update(int $id, UpdateMesaDTO $dto): Mesa
    {
        $mesa = Mesa::findOrFail($id);
        $mesa->update($dto->toArray());
        return $mesa->fresh(['ordenActiva.detalles']);
    }

    public function delete(int $id): bool
    {
        $mesa = Mesa::findOrFail($id);

        if ($mesa->estado !== 'Libre' || $mesa->orden_activa_id !== null) {
            throw new Exception('No se puede eliminar una mesa que está ocupada o con comanda activa.');
        }

        return (bool) $mesa->delete();
    }

    public function abrirMesa(int $id, AbrirMesaDTO $dto): Mesa
    {
        return DB::transaction(function () use ($id, $dto) {
            $mesa = Mesa::lockForUpdate()->findOrFail($id);

            if ($mesa->estado !== 'Libre' && $mesa->orden_activa_id !== null) {
                throw new Exception('La mesa ya tiene una orden activa.');
            }

            $fecha = date('Y-m-d');
            $maxSecuencia = Pedido::where('fecha', $fecha)->max('secuencia_diaria');
            $secuencia = $maxSecuencia ? $maxSecuencia + 1 : 1;

            $total = 0;
            foreach ($dto->detalles as $det) {
                $total += ((float) $det['cantidad']) * ((float) $det['precio_unitario']);
            }

            $clienteNombre = !empty($dto->clienteNombre)
                ? $dto->clienteNombre
                : $mesa->nombre;

            $pedido = Pedido::create([
                'secuencia_diaria' => $secuencia,
                'fecha'            => $fecha,
                'cliente_nombre'   => $clienteNombre,
                'cliente_telefono' => $dto->clienteTelefono ?? '',
                'direccion'        => 'Mesa: ' . $mesa->nombre . ' (' . $mesa->area . ')',
                'tipo_entrega'     => 'Local',
                'estado'           => 'Preparando',
                'total'            => $total,
                'nota'             => $dto->nota ?? ('Mesa: ' . $mesa->nombre),
                'mesa_id'          => $mesa->id,
                'codigo_barras'    => $this->pedidoService->generateEan13(),
            ]);

            foreach ($dto->detalles as $det) {
                $cant = (float) $det['cantidad'];
                $precio = (float) $det['precio_unitario'];
                PedidoDetalle::create([
                    'pedido_id'       => $pedido->id,
                    'producto_id'     => $det['producto_id'],
                    'nombre_producto' => $det['nombre_producto'],
                    'cantidad'        => $cant,
                    'precio_unitario' => $precio,
                    'subtotal'        => $cant * $precio,
                ]);
            }

            $mesa->update([
                'estado'          => 'Ocupada',
                'orden_activa_id' => $pedido->id,
            ]);

            return $mesa->fresh(['ordenActiva.detalles']);
        });
    }

    public function agregarItems(int $id, AgregarItemsMesaDTO $dto): Mesa
    {
        return DB::transaction(function () use ($id, $dto) {
            $mesa = Mesa::lockForUpdate()->findOrFail($id);

            if (!$mesa->orden_activa_id) {
                throw new Exception('La mesa no tiene una orden activa.');
            }

            $pedido = Pedido::lockForUpdate()->findOrFail($mesa->orden_activa_id);

            $montoAdicional = 0;
            foreach ($dto->detalles as $det) {
                $cant = (float) $det['cantidad'];
                $precio = (float) $det['precio_unitario'];
                $subtotal = $cant * $precio;
                $montoAdicional += $subtotal;

                PedidoDetalle::create([
                    'pedido_id'       => $pedido->id,
                    'producto_id'     => $det['producto_id'],
                    'nombre_producto' => $det['nombre_producto'],
                    'cantidad'        => $cant,
                    'precio_unitario' => $precio,
                    'subtotal'        => $subtotal,
                ]);
            }

            $pedido->total += $montoAdicional;
            if (!empty($dto->nota)) {
                $pedido->nota = trim(($pedido->nota ?? '') . ' | Adición: ' . $dto->nota);
            }
            $pedido->save();

            // Si estaba en PorCobrar, vuelve a Ocupada
            if ($mesa->estado === 'PorCobrar') {
                $mesa->estado = 'Ocupada';
                $mesa->save();
            }

            return $mesa->fresh(['ordenActiva.detalles']);
        });
    }

    public function solicitarCuenta(int $id): Mesa
    {
        $mesa = Mesa::findOrFail($id);
        if (!$mesa->orden_activa_id) {
            throw new Exception('La mesa no tiene comanda activa para solicitar cuenta.');
        }

        $mesa->update(['estado' => 'PorCobrar']);
        return $mesa->fresh(['ordenActiva.detalles']);
    }

    public function liberarMesa(int $id): Mesa
    {
        return DB::transaction(function () use ($id) {
            $mesa = Mesa::lockForUpdate()->findOrFail($id);

            if ($mesa->orden_activa_id) {
                $pedido = Pedido::find($mesa->orden_activa_id);
                if ($pedido && $pedido->estado !== 'Facturado' && $pedido->estado !== 'Cancelado') {
                    $pedido->estado = 'Facturado';
                    $pedido->save();
                }
            }

            $mesa->update([
                'estado'          => 'Libre',
                'orden_activa_id' => null,
            ]);

            return $mesa->fresh();
        });
    }

    public function getAreas(): array
    {
        $areas = Mesa::select('area')->distinct()->pluck('area')->toArray();
        if (empty($areas)) {
            $areas = ['Principal'];
        }
        return $areas;
    }
}
