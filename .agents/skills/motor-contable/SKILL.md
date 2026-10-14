---
name: motor-contable
description: >-
  Use this skill whenever the user asks to "incluir la contabilidad", create or adjust
  automatic accounting entries (asientos contables por partida doble), or integrate business
  transactions (compras, ventas, pagos, gastos, nómina) with the accounting system.
---

# Motor Contable Automático (Partida Doble)

Usa esta skill para conectar cualquier operación del sistema (compras, ventas, pagos, nóminas, etc.) con el motor de contabilidad automática.

## Manual Completo de Referencia
Lee siempre la documentación técnica detallada en:
`backend/app/Modules/Contabilidad/README.md`

## Procedimiento Estándar para "Incluir la Contabilidad":

### 1. Identificar el Tipo de Transacción
* Compras regulares o con retención informal: `compra_inventario`
* Pago a proveedores (cancelación de CxP): `pago_compra`
* Ventas de contado (mostrador/caja): `venta_efectivo`
* Ventas a crédito (facturas por cobrar): `venta_credito`
* Cobros a clientes (abono a CxC): `pago_cxc`
* Desembolso de nómina de empleados: `pago_nomina`
* Pago de ITBIS a la DGII: `pago_dgii`

### 2. Construir el DTO Inmutable
```php
use App\Modules\Contabilidad\DTOs\RegistrarAsientoDTO;
use App\Modules\Contabilidad\Services\ContabilidadService;

$dto = new RegistrarAsientoDTO(
    tipo_transaccion: 'compra_inventario',
    subtotal: $subtotal,
    itbis: $itbis,
    total: $total,
    referencia: $documentoReferencia,
    glosa: "Descripción clara del hecho contable",
    usuario_id: auth()->id(),
    custom_configs: [
        'es_informal' => $esProveedorInformal, // Retiene 100% ITBIS si es true
        'detalles' => $detallesArray ?? [],   // Permite mapear cuentas específicas por ítem
    ],
    costo: $costoIngredientes ?? 0.0          // Para salida automática de inventario en ventas
);
```

### 3. Disparar el Asiento
```php
$asiento = app(ContabilidadService::class)->registrarAsientoAuto($dto);
```

## Reglas Críticas:
1. **Zero Hardcoded Accounts:** No asignes cuentas manuales en duro en el código (`cuenta_id = 1`). Deja que `ContabilidadService` use `ConfiguracionContableService` y la tabla `configuraciones_contables`.
2. **Partida Doble:** Los débitos deben igualar a los créditos. La base de datos arrojará `ContabilidadException` y revertirá la transacción si no cuadra.
3. **Cuentas de Detalle:** Toda cuenta debe tener `permite_movimiento == true`.
