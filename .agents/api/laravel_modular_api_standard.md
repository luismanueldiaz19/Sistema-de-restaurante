# 🏛️ Guía y Reglas de Arquitectura Modular para APIs en Laravel

Este documento define el estándar universal para la construcción de APIs RESTful en Laravel utilizando un enfoque modular guiado por dominio (Domain-Driven / Modular Monolith).

---

## 1. Filosofía y Reglas Fundamentales

1. **Aislamiento de Dominio**: Cada carpeta dentro de `app/Modules/<Modulo>/` debe contener toda su lógica (rutas, controladores, DTOs, servicios, persistencia y tests).
2. **Controlador Delgado (Slim Controller)**:
   - Valida vía `FormRequest`.
   - Mapea el request a un `DTO`.
   - Delega la lógica al `Service`.
   - Serializa la salida con un `Resource` o respuesta unificada.
3. **Servicio con Lógica Pura y Transaccional**:
   - Administra la lógica de negocio, cálculos e idempotencia.
   - Ejecuta operaciones complejas dentro de `DB::transaction()`.
   - Utiliza contratos (`RepositoryInterface`) para persistencia o interacción de datos.
4. **Excepciones de Dominio**:
   - No retornar arrays de error desde los servicios.
   - Lanzar excepciones customizadas (`StockInsuficienteException`) que definan su propio render HTTP o código de estado.
5. **Tipado Estricto**:
   - Uso de `declare(strict_types=1);` en todos los archivos.
   - Tipos de retorno y parámetros fuertemente declarados.
6. **Uso Obligatorio de Enums**:
   - Los campos de tipo "estado", "tipo", o con un listado cerrado de valores (ej. `PENDIENTE`, `APROBADO`, `ACTIVO`) DEBEN implementarse usando PHP 8.1 Enums nativos (`App\Modules\<Modulo>\Enums\<Nombre>Enum.php`).
   - La validación en `FormRequest` DEBE usar `\Illuminate\Validation\Rule::enum()`.
   - Se debe crear su contraparte en el frontend en `Frontend/lib/<modulo>/enums/<nombre>_enum.dart` para mantener sincronía.
7. **Generación Completa y Obligatoria del Módulo**:
   - Al crear o migrar un módulo, el agente DEBE crear **todos** los componentes del estándar sin excepción: DTOs, FormRequests, Controllers, Services, Exceptions, Rutas, y **SIEMPRE la clase Policy** (`App\Modules\<Modulo>\Policies\<Nombre>Policy.php`).
   - La Policy recién creada DEBE registrarse inmediatamente en `app/Providers/AuthServiceProvider.php` dentro del arreglo `$policies`, de lo contrario Laravel no la descubrirá debido al cambio de namespace.
8. **Generación de Enlaces Cortos Universales para PDFs/Documentos (Shortlinks)**:
   - Todo módulo que genere PDFs o documentos para compartir (Facturas, Cotizaciones, Órdenes, etc.) DEBE usar la ruta corta universal `/d/{token}` en lugar de crear rutas de PDF dentro de su propia API.
   - El controlador/servicio debe generar un `$token = Str::random(40);`, y hacer `Cache::put("short_link_{$token}", ['type' => 'modulo', 'id' => $id, ...], now()->addHours(24));`.
   - El enlace debe resolverse agregando la lógica al `DocumentLinkController` (`App\Modules\Shared\Http\Controllers\DocumentLinkController.php`).

---

## 2. Árbol de Estructura Canónica

```text
app/
├── Modules/
│   ├── [NombreModulo]/                      # Ej: Pedido, Vehiculo, Facturacion
│   │   ├── Providers/
│   │   │   └── [NombreModulo]ServiceProvider.php
│   │   ├── Routes/
│   │   │   └── api.php                      # Endpoints del módulo (/api/v1/pedidos)
│   │   ├── Http/
│   │   │   ├── Controllers/
│   │   │   │   └── [Nombre]Controller.php
│   │   │   ├── Requests/
│   │   │   │   ├── Store[Nombre]Request.php
│   │   │   │   └── Update[Nombre]Request.php
│   │   │   └── Resources/
│   │   │       ├── [Nombre]Resource.php
│   │   │       └── [Nombre]DetalleResource.php
│   │   ├── DTOs/
│   │   │   └── [Accion][Nombre]DTO.php      # Ej: CreatePedidoDTO.php
│   │   ├── Services/
│   │   │   └── [Nombre]Service.php
│   │   ├── Repositories/
│   │   │   ├── Contracts/
│   │   │   │   └── [Nombre]RepositoryInterface.php
│   │   │   └── Eloquent[Nombre]Repository.php
│   │   ├── Models/
│   │   │   └── [Nombre].php
│   │   ├── Policies/
│   │   │   └── [Nombre]Policy.php
│   │   ├── Exceptions/
│   │   │   └── [Nombre]Exception.php
│   │   └── Tests/
│   │       ├── Feature/
│   │       └── Unit/
│   │
│   └── Shared/                              # Componentes transversales
│       ├── Traits/
│       │   └── ApiResponseTrait.php
│       ├── Enums/
│       │   └── CommonEnums.php
│       ├── DTOs/
│       │   └── BaseDTO.php
│       ├── Exceptions/
│       │   └── DomainException.php
│       └── Providers/
│           └── ModularServiceProvider.php
```

---

## 3. Implementación Paso a Paso

### 3.1. DTO (Data Transfer Object)
```php
<?php

declare(strict_types=1);

namespace App\Modules\Pedido\DTOs;

use App\Modules\Pedido\Http\Requests\StorePedidoRequest;

final readonly class CreatePedidoDTO
{
    public function __construct(
        public int $clienteId,
        public array $items,
        public ?string $notas = null
    ) {}

    public static function fromRequest(StorePedidoRequest $request): self
    {
        return new self(
            clienteId: (int) $request->validated('cliente_id'),
            items: (array) $request->validated('items'),
            notas: $request->validated('notas')
        );
    }
}
```

### 3.2. FormRequest con Autorización y Validación
```php
<?php

declare(strict_types=1);

namespace App\Modules\Pedido\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class StorePedidoRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true; // O vincular con $this->user()->can('create', Pedido::class);
    }

    public function rules(): array
    {
        return [
            'cliente_id' => ['required', 'integer', 'exists:clientes,id'],
            'items' => ['required', 'array', 'min:1'],
            'items.*.producto_id' => ['required', 'integer', 'exists:productos,id'],
            'items.*.cantidad' => ['required', 'integer', 'min:1'],
            'notas' => ['nullable', 'string', 'max:255'],
        ];
    }
}
```

### 3.3. Service con Transacción y Reglas de Negocio
```php
<?php

declare(strict_types=1);

namespace App\Modules\Pedido\Services;

use App\Modules\Pedido\DTOs\CreatePedidoDTO;
use App\Modules\Pedido\Exceptions\StockInsuficienteException;
use App\Modules\Pedido\Models\Pedido;
use App\Modules\Pedido\Repositories\Contracts\PedidoRepositoryInterface;
use Illuminate\Support\Facades\DB;

class PedidoService
{
    public function __construct(
        private readonly PedidoRepositoryInterface $pedidoRepository
    ) {}

    public function create(CreatePedidoDTO $dto): Pedido
    {
        return DB::transaction(function () use ($dto) {
            // 1. Validar reglas de dominio
            foreach ($dto->items as $item) {
                if ($item['cantidad'] > 100) { // Ejemplo de regla
                    throw new StockInsuficienteException("Stock insuficiente para el producto #{$item['producto_id']}");
                }
            }

            // 2. Persistencia
            return $this->pedidoRepository->createWithItems($dto);
        });
    }
}
```

### 3.4. Controller Orquestador
```php
<?php

declare(strict_types=1);

namespace App\Modules\Pedido\Http\Controllers;

use App\Http\Controllers\Controller;
use App\Modules\Pedido\DTOs\CreatePedidoDTO;
use App\Modules\Pedido\Http\Requests\StorePedidoRequest;
use App\Modules\Pedido\Http\Resources\PedidoResource;
use App\Modules\Pedido\Services\PedidoService;
use App\Modules\Shared\Traits\ApiResponseTrait;
use Illuminate\Http\JsonResponse;

class PedidoController extends Controller
{
    use ApiResponseTrait;

    public function __construct(
        private readonly PedidoService $pedidoService
    ) {}

    public function store(StorePedidoRequest $request): JsonResponse
    {
        $dto = CreatePedidoDTO::fromRequest($request);
        $pedido = $this->pedidoService->create($dto);

        return $this->successResponse(
            data: new PedidoResource($pedido),
            message: 'Pedido creado exitosamente',
            code: 201
        );
    }
}
```

### 3.5. ApiResponseTrait Compartido
```php
<?php

declare(strict_types=1);

namespace App\Modules\Shared\Traits;

use Illuminate\Http\JsonResponse;

trait ApiResponseTrait
{
    protected function successResponse(mixed $data = null, string $message = 'Success', int $code = 200): JsonResponse
    {
        return response()->json([
            'success' => true,
            'message' => $message,
            'data'    => $data,
        ], $code);
    }

    protected function errorResponse(string $message = 'Error', int $code = 400, mixed $errors = null): JsonResponse
    {
        return response()->json([
            'success' => false,
            'message' => $message,
            'errors'  => $errors,
        ], $code);
    }
}
```

---

## 4. Registro y Autodescubrimiento

Para registrar automáticamente todas las rutas y proveedores de los módulos sin tocar el core de Laravel repetidamente, añade este `ModularServiceProvider`:

```php
<?php

declare(strict_types=1);

namespace App\Modules\Shared\Providers;

use Illuminate\Support\Facades\Route;
use Illuminate\Support\ServiceProvider;

class ModularServiceProvider extends ServiceProvider
{
    public function boot(): void
    {
        $modulesPath = app_path('Modules');

        if (!is_dir($modulesPath)) {
            return;
        }

        $modules = array_diff(scandir($modulesPath), ['.', '..', 'Shared']);

        foreach ($modules as $module) {
            $routesFile = "{$modulesPath}/{$module}/Routes/api.php";
            if (file_exists($routesFile)) {
                Route::prefix('api/v1')
                    ->middleware('api')
                    ->group($routesFile);
            }
        }
    }
}
```

*Regístralo en `bootstrap/providers.php`.*