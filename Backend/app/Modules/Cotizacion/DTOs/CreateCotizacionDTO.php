<?php

declare(strict_types=1);

namespace App\Modules\Cotizacion\DTOs;

use App\Modules\Cotizacion\Http\Requests\StoreCotizacionRequest;

final readonly class CreateCotizacionDTO
{
    public function __construct(
        public int $clienteId,
        public string $fechaEmision,
        public ?string $fechaVencimiento,
        public array $detalles,
        public ?string $nota,
        public int $userId,
        public array $companyData
    ) {}

    public static function fromRequest(StoreCotizacionRequest $request): self
    {
        return new self(
            clienteId: (int) $request->validated('cliente_id'),
            fechaEmision: $request->validated('fecha_emision'),
            fechaVencimiento: $request->validated('fecha_vencimiento'),
            detalles: $request->validated('detalles'),
            nota: $request->validated('nota'),
            userId: $request->user()->id,
            companyData: [
                'company_name' => $request->validated('company_name'),
                'company_rnc' => $request->validated('company_rnc'),
                'company_address' => $request->validated('company_address'),
                'company_phone' => $request->validated('company_phone'),
            ]
        );
    }
}
