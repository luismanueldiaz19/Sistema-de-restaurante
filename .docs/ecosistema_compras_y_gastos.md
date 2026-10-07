# Ecosistema de Compras y Gastos - Especificación Técnica y Contable

Este documento define la arquitectura para manejar adquisiciones (Compras) y consumos (Gastos), incluyendo el soporte para **Apartados** y pagos anticipados, bajo un estándar de **Senior Developer** y **Contador Profesional**.

---

## 1. Compras vs. Gastos: La Diferencia Vital

Para el sistema, ambos son registros de facturas de proveedores, pero su destino contable es distinto:

| Característica | Compras (Activos/Inventario) | Gastos (Operativos) |
| :--- | :--- | :--- |
| **Destino** | Almacén o Patrimonio (Ej: Arroz, Freidora) | Consumo inmediato (Ej: Luz, Alquiler) |
| **Efecto Contable** | Aumenta un **Activo** (Cuenta 1xxx) | Aumenta un **Gasto** (Cuenta 6xxx) |
| **Recuperación** | Se recupera vía venta o uso a largo plazo | No se recupera, reduce la utilidad del mes |

---

## 2. Soporte para "Apartados" (Anticipos)

Un **Apartado** ocurre cuando pagas una parte o el total de algo antes de recibir la factura legal o el producto.

### Lógica Contable del Apartado:
1. **Al pagar el apartado**:
   - `Débito`: Anticipos a Proveedores (Activo - El proveedor me debe ese dinero o el equipo).
   - `Crédito`: Caja/Banco.
2. **Al recibir la factura y el equipo**:
   - `Débito`: Activo Fijo / Inventario.
   - `Crédito`: Anticipos a Proveedores (Se cancela la deuda del proveedor conmigo).
   - `Crédito`: Cuentas por Pagar (Si queda un saldo pendiente).

---

## 3. Estados de la Compra (Ciclo de Vida)

Para soportar apartados y compras normales, el documento de compra debe tener estos estados:

- **Borrador/Cotización**: Sin efecto contable.
- **Apartado/Pendiente de Entrega**: Se han realizado pagos, pero la mercancía no ha llegado.
- **Recibida/Completada**: La mercancía llegó y la factura está registrada.
- **Anulada**: Registro cancelado.

---

## 4. Estructura de Datos (PostgreSQL)

```sql
-- 1. Tabla Maestra de Compras y Gastos
CREATE TABLE compras (
    id SERIAL PRIMARY KEY,
    proveedor_id INT REFERENCES proveedores(id),
    tipo_documento VARCHAR(20), -- 'Factura', 'Recibo', 'Cotizacion'
    ncf VARCHAR(20), -- Comprobante Fiscal (RD)
    fecha_emision DATE NOT NULL,
    fecha_vencimiento DATE, -- Para Cuentas por Pagar
    subtotal DECIMAL(15,2) NOT NULL,
    itbis DECIMAL(15,2) DEFAULT 0,
    otros_impuestos DECIMAL(15,2) DEFAULT 0,
    total DECIMAL(15,2) NOT NULL,
    monto_pendiente DECIMAL(15,2), -- Importante para pagos parciales
    estado VARCHAR(20) DEFAULT 'Borrador', -- Borrador, Apartado, Completada, Anulada
    notas TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 2. Detalle de la Compra (Items)
CREATE TABLE compra_detalles (
    id SERIAL PRIMARY KEY,
    compra_id INT REFERENCES compras(id) ON DELETE CASCADE,
    descripcion TEXT NOT NULL,
    cantidad DECIMAL(12,2) NOT NULL,
    precio_unitario DECIMAL(15,2) NOT NULL,
    itbis_monto DECIMAL(15,2) DEFAULT 0,
    subtotal DECIMAL(15,2) NOT NULL,
    -- Aquí se decide el destino contable:
    cuenta_contable_id INT REFERENCES catalogo_cuentas(id), 
    producto_id INT NULL, -- Si es para inventario de comida
    activo_fijo_id INT NULL -- Si es un equipo (vincula con modulo_activos_fijos)
);

-- 3. Registro de Pagos (Soporta Apartados y Abonos)
CREATE TABLE compra_pagos (
    id SERIAL PRIMARY KEY,
    compra_id INT REFERENCES compras(id),
    fecha_pago TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    monto_pagado DECIMAL(15,2) NOT NULL,
    metodo_pago VARCHAR(20), -- Efectivo, Transferencia, Tarjeta
    referencia_pago VARCHAR(100), -- Num. Transacción
    es_anticipo BOOLEAN DEFAULT FALSE, -- TRUE si es un Apartado sin factura
    cuenta_origen_id INT REFERENCES catalogo_cuentas(id) -- Cuenta de Banco/Caja
);
```

---

## 5. UI/UX Strategy (Flutter)

### Pantalla de "Nueva Compra/Gasto":
- **Header**: Selector de Proveedor, NCF y Fecha.
- **Body**: Tabla dinámica para agregar filas. Cada fila permite elegir si es un "Producto de Inventario", un "Activo Fijo" o un "Gasto Operativo".
- **Footer**:
    - Botón **"Guardar como Apartado"**: Permite registrar el pago inicial sin cerrar la factura.
    - Botón **"Finalizar Compra"**: Cierra el documento y afecta inventario/activos.

---

## 6. Recomendaciones de Senior Developer

1. **Validación de NCF**: El sistema debe validar que el NCF tenga el formato correcto para evitar errores en los reportes de la DGII (606).
2. **Cierre de Mes**: Una vez que un gasto es "Completado" y el mes contable cierra, el registro debe bloquearse para edición.
3. **Manejo de Inventario**: Si el detalle es un producto, el `Service` de compras debe llamar al `InventarioService` para aumentar el stock automáticamente.

---
> [!IMPORTANT]
> Esta estructura permite que el restaurante crezca. Puedes empezar registrando gastos simples (luz, agua) y luego usar el mismo módulo para compras complejas de maquinaria (freidoras) con pagos por cuotas o apartados.
