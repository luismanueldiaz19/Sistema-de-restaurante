<?php

declare(strict_types=1);

namespace App\Modules\Compra\DTOs;

use App\Modules\Compra\Http\Requests\StoreCompraRequest;
use App\Modules\Compra\Enums\CompraTipoEnum;

final readonly class CreateCompraDTO
{
    public function __construct(
        public int $proveedor_id,
        public string $numero_factura_proveedor,
        public ?string $ncf,
        public string $fecha_compra,
        public ?string $fecha_vencimiento,
        public CompraTipoEnum $tipo_compra,
        public ?int $metodo_pago_id,
        public ?string $referencia_pago,
        public ?string $notas,
        public ?string $idempotency_key,
        public array $detalles
    ) {}

    public static function fromRequest(StoreCompraRequest $request): self
    {
        return new self(
            proveedor_id: (int) $request->proveedor_id,
            numero_factura_proveedor: $request->numero_factura_proveedor,
            ncf: $request->ncf,
            fecha_compra: $request->fecha_compra,
            fecha_vencimiento: $request->fecha_vencimiento,
            tipo_compra: CompraTipoEnum::from($request->tipo_compra),
            metodo_pago_id: $request->metodo_pago_id ? (int) $request->metodo_pago_id : null,
            referencia_pago: $request->referencia_pago,
            notas: $request->notas,
            idempotency_key: $request->idempotency_key,
            detalles: $request->detalles
        );
    }
}
