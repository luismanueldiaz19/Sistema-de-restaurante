<?php

declare(strict_types=1);

namespace App\Modules\Producto\DTOs;

use App\Modules\Producto\Http\Requests\UpdateProductoRequest;

final readonly class UpdateProductoDTO
{
    public function __construct(
        public array $data
    ) {}

    public static function fromRequest(UpdateProductoRequest $request): self
    {
        return new self(
            data: $request->validated()
        );
    }

    public function toArray(): array
    {
        return $this->data;
    }
}
