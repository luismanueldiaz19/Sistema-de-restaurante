# Motor de Operaciones Contables Automáticas

## Objetivo

Diseñar un motor contable configurable que permita generar asientos contables automáticamente según el tipo de operación realizada en el sistema.

El objetivo es evitar lógica contable hardcodeada en el código fuente y permitir que las operaciones puedan configurarse desde base de datos.

---

# Concepto General

Toda operación del sistema:

- ventas
- compras
- pagos
- cobros
- gastos
- inventario
- nómina
- depreciaciones

debe generar automáticamente un asiento contable basado en reglas configuradas.

---

# Flujo General

```text
Documento/Transacción
        ↓
Tipo de Operación
        ↓
Configuración Contable
        ↓
Generador de Asiento
        ↓
Asiento Contable


Backend/app/
├── Accounting/
│   ├── AsientoStrategy.php           (Interfaz o contrato contable)
│   ├── AsientoStrategyFactory.php    (Fábrica que decide qué estrategia usar)
│   └── Strategies/
│       ├── VentaEfectivoStrategy.php  (Asiento de Venta Contado)
│       ├── VentaCreditoStrategy.php   (Asiento de Venta Crédito)
│       ├── CompraInventarioStrategy.php(Asiento de Compras)
│       └── PagoNominaStrategy.php     (Asiento de Nómina/Salarios)
└── Services/
    └── ContabilidadService.php       (Limpiado y simplificado)
