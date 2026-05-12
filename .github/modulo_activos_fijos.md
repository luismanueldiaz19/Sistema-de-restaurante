# Módulo de Activos Fijos e Inversión Inicial - Especificación Técnica y Contable

Este documento detalla la arquitectura, lógica contable y requerimientos técnicos para la implementación del módulo de **Activos Fijos** (Mobiliario, Maquinaria) y **Registro de Inversión Inicial**, actuando bajo el rol de **Contador Profesional** y **Senior Developer**.

---

## 1. Visión General
El objetivo de este módulo es permitir que la empresa registre:
1. **Inversión Inicial**: El capital aportado por los socios para arrancar el negocio.
2. **Adquisición de Activos**: Registro de equipos que no son para la venta (Freidoras, Mesas, Vitrinas) sino para la operación.
3. **Control Patrimonial**: Saber cuánto vale la empresa en términos de equipamiento y liquidez.

---

## 2. Lógica Contable (Visión de Contador)

### A. Registro de Inversión (Capital)
Cuando el dueño aporta dinero para iniciar, se debe generar un asiento contable:
- **Débito**: Cuenta de Activo (Efectivo/Banco). *Aumenta el dinero disponible.*
- **Crédito**: Cuenta de Capital (Capital Social/Aportes). *Aumenta la deuda de la empresa con sus dueños.*

### B. Adquisición de Activos Fijos
Al comprar una freidora o una mesa:
- **Débito**: Cuenta de Activo Fijo (Maquinaria y Equipos / Mobiliario). *Aumenta el patrimonio físico.*
- **Crédito**: Cuenta de Activo (Efectivo/Banco) o Pasivo (Cuentas por Pagar). *Disminuye el efectivo o aumenta la deuda.*

### C. Depreciación (Importante para el futuro)
Los activos pierden valor con el tiempo (desgaste). El sistema debe estar preparado para calcular la depreciación mensual:
- **Gasto por Depreciación** (Débito)
- **Depreciación Acumulada** (Crédito - Cuenta que resta al valor del activo).

---

## 3. Arquitectura Técnica (Visión Senior Developer)

Siguiendo los principios **SOLID** y la arquitectura del proyecto:

### A. Modelos y Entidades
- `ActivoFijoModel`: Representa el objeto físico (Nombre, Marca, Serie, Costo Original).
- `InversionModel`: Registro del origen de los fondos.
- `AsientoContableModel`: El "Journal Entry" que vincula la transacción con el Catálogo de Cuentas.

### B. Flujo de Datos
1. El usuario registra una "Compra de Activo".
2. El sistema valida que la cuenta contable de "Activos Fijos" exista.
3. Se crea el registro en la tabla `activos_fijos`.
4. Automáticamente se genera un **Asiento Contable** de doble entrada para afectar el balance general.

---

## 4. Estructura de Datos (PostgreSQL)

Proponemos las siguientes tablas para complementar el `catalogo_cuentas` ya existente:

```sql
-- 1. Tabla de Activos Fijos
CREATE TABLE activos_fijos (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(150) NOT NULL, -- Ej: Freidora Industrial 20L
    descripcion TEXT,
    codigo_inventario VARCHAR(50) UNIQUE, -- Placa de activo fijo
    fecha_adquisicion DATE NOT NULL,
    costo_compra DECIMAL(15,2) NOT NULL,
    valor_residual DECIMAL(15,2) DEFAULT 0, -- Lo que valdrá al final de su vida útil
    vida_util_meses INT, -- Ej: 60 meses (5 años)
    estado_activo VARCHAR(20) DEFAULT 'Operativo', -- Operativo, En Mantenimiento, Retirado
    cuenta_contable_id INT REFERENCES catalogo_cuentas(id), -- Vinculación contable
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 2. Tabla de Asientos Contables (Libro Diario)
CREATE TABLE asientos_contables (
    id SERIAL PRIMARY KEY,
    fecha DATE NOT NULL,
    glosa TEXT, -- Concepto: "Registro de inversión inicial" o "Compra de Vitrina"
    referencia VARCHAR(50), -- Número de factura o recibo
    usuario_id INT REFERENCES users(id),
    estado VARCHAR(20) DEFAULT 'Posteado', -- Borrador, Posteado, Anulado
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 3. Detalle del Asiento (Partida Doble)
CREATE TABLE asiento_detalles (
    id SERIAL PRIMARY KEY,
    asiento_id INT REFERENCES asientos_contables(id) ON DELETE CASCADE,
    cuenta_id INT REFERENCES catalogo_cuentas(id),
    debito DECIMAL(15,2) DEFAULT 0,
    credito DECIMAL(15,2) DEFAULT 0,
    CONSTRAINT partida_doble_check CHECK (debito >= 0 AND credito >= 0)
);
```

---

## 5. UI/UX Strategy (Flutter)

### Pantallas Sugeridas:
1. **Panel de Inversión**: Un formulario simple donde se registra el "Capital Inicial". El sistema hace el asiento `Banco (D) vs Capital (C)`.
2. **Gestión de Activos Fijos**:
   - Vista de Lista con fotos de los equipos.
   - Botón "Registrar Nuevo Activo" (Pide: Nombre, Costo, Fecha, Cuenta de pago).
3. **Reporte de Patrimonio**: Un resumen que diga: "Tienes RD$ X en Banco y RD$ Y en Equipos. Tu inversión total es Z".

### Componentes Reutilizables:
- `AssetCard`: Muestra miniatura del activo y su valor actual.
- `AccountingEntryPreview`: Un pequeño widget que muestra cómo quedará el asiento (Débitos y Créditos) antes de guardar, para que el usuario se sienta seguro.

---

## 6. Ejemplo de Registro (Caso de Uso)

**Acción**: Usuario registra "Compra de Mesa" por RD$ 5,000 en efectivo.

1. **Tabla `activos_fijos`**: Se inserta "Mesa de Madera", costo 5,000.
2. **Tabla `asientos_contables`**: Se inserta "Compra de mobiliario según factura #123".
3. **Tabla `asiento_detalles`**:
   - Línea 1: Cuenta `1201-01 (Mobiliario)` -> **Débito: 5,000**
   - Línea 2: Cuenta `1101-01 (Caja/Banco)` -> **Crédito: 5,000**

---

## 7. Recomendaciones de Senior Developer
- **Atomicidad**: La creación del activo y el asiento contable deben ocurrir dentro de una **Transacción de Base de Datos**. Si falla el asiento, no debe crearse el activo.
- **Validación de Saldo**: Antes de comprar un activo, el sistema debería avisar si hay suficiente dinero en la cuenta de "Caja/Banco" (opcional pero profesional).
- **Auditoría**: Siempre guardar qué usuario registró el activo para evitar fraudes.

---

## 8. Integración con el Módulo de Compras (Arquitectura Eficiente)

Para evitar duplicidad de código y centralizar el control fiscal (NCF) y de proveedores, **la compra de activos debe integrarse en el módulo de Compras/Gastos existente**, bajo la siguiente lógica:

1.  **Entrada Única**: El registro de la factura del proveedor se hace en el módulo de Compras. Esto garantiza que el ITBIS, el NCF y la Cuenta por Pagar se manejen de forma estándar.
2.  **Clasificación**: Al registrar el detalle de la compra, el usuario selecciona la categoría o cuenta contable. 
    - Si la cuenta pertenece al grupo de **Activos (12xx)**, el sistema activa automáticamente el módulo de activos fijos.
3.  **Vinculación Directa**: La tabla `activos_fijos` debe tener un campo `compra_id` que apunte a la factura original. Esto permite saber a qué proveedor se le compró y qué garantía tiene.

---
> [!TIP]
> Implementar esto paso a paso permitirá que cuando lleguemos al módulo de "Contabilidad General", ya tengamos toda la data histórica de activos e inversiones lista para generar el **Balance General**.
