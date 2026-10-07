
Cada carpeta de módulo repite exactamente 
el patrón que ya armamos para Pedido 
(Http/Controllers, Http/Requests, Models, Services, Repositories, Policies). 
No es una estructura nueva — es la misma, replicada por dominio:

app/Modules/
├── Vehiculo/
│   ├── Http/{Controllers,Requests,Resources}/
│   ├── Models/
│   ├── Services/
│   ├── Repositories/
│   └── Policies/
├── Mantenimiento/     ← mismo patrón
├── Pedido/             ← mismo patrón (el que ya armamos)
├── Inventario/         ← mismo patrón
└── Shared/
    ├── Enums/          # Ej: EstadoPedido, si otros módulos lo necesitan
    └── Traits/