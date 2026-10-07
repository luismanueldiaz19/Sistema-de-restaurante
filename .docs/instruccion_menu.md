# Reestructuración de Menú ERP Restaurante - MENUXA

## Objetivo

Reorganizar el menú lateral del sistema MENUXA siguiendo una estructura basada en procesos de negocio y no en entidades individuales.

Actualmente existen módulos independientes como Clientes, Proveedores, CxC, Gastos, Caja y Bancos, etc. Esto provoca que el usuario tenga que pensar dónde está cada dato en lugar de pensar en el proceso que desea realizar.

La nueva estructura debe agrupar funcionalidades relacionadas dentro de módulos de negocio.

---

# Nueva Estructura del Menú

## Dashboard

```text
Dashboard
```

---

## Operaciones

Todo lo relacionado con la operación comercial del restaurante.

```text
Operaciones
├── Punto de Venta (POS)
├── Nueva Venta
├── Facturas
├── Cotizaciones
├── Devoluciones
└── Clientes
```

### Reglas

* El módulo Clientes deja de ser un menú principal.
* Clientes pasa a pertenecer al módulo Operaciones.
* Todas las ventas y facturación deben estar centralizadas aquí.

---

## Inventario

Todo lo relacionado con productos e insumos.

```text
Inventario
├── Productos
├── Ingredientes
├── Categorías
├── Kardex
├── Ajustes de Inventario
├── Transferencias
└── Recetas
```

### Reglas

* Los ingredientes deben formar parte del inventario.
* Kardex debe mostrar entradas, salidas y existencias.
* Las recetas servirán para descontar automáticamente ingredientes al vender productos terminados.

---

## Compras

Todo lo relacionado con abastecimiento.

```text
Compras
├── Nueva Compra
├── Historial de Compras
├── Proveedores
├── Cuentas por Pagar
└── Pagos Realizados
```

### Reglas

* Proveedores deja de ser un menú principal.
* Cuentas por Pagar pertenece a Compras.
* Todo gasto relacionado con suplidores debe gestionarse aquí.

---

## Finanzas

Todo lo relacionado con flujo de dinero.

```text
Finanzas
├── Caja
│   ├── Apertura
│   ├── Cierre
│   └── Movimientos
│
├── Bancos
│
├── Cuentas por Cobrar
│
└── Gastos
```

### Reglas

Eliminar los siguientes módulos principales:

```text
Caja y Bancos
CxC
Gastos
```

Estos deben integrarse dentro de Finanzas.

---

## Contabilidad

Módulo contable formal.

```text
Contabilidad
├── Catálogo de Cuentas
├── Diario General
├── Mayor General
├── Balance General
├── Estado de Resultados
└── Asientos Contables
```

### Reglas

Toda la información financiera debe poder generar asientos contables automáticos.

---

## Recursos Humanos

```text
RRHH
├── Dashboard Nómina
├── Empleados
├── Generar Nómina
├── Vacaciones
└── Asistencia
```

### Reglas

El módulo Nómina debe convertirse en RRHH.

---

## DGII

```text
DGII
├── NCF
├── e-CF
├── Reporte 606
├── Reporte 607
├── Reporte 608
├── Reporte 609
└── Reportes DGII
```

### Reglas

Toda la integración fiscal debe centralizarse aquí.

---

## Reportes

```text
Reportes
├── Ventas
├── Compras
├── Inventario
├── Finanzas
├── RRHH
└── Contabilidad
```

### Reglas

No almacenar lógica de negocio dentro de reportes.
Los reportes solo consumen información de otros módulos.

---

## Administración

```text
Administración
├── Usuarios
├── Roles
├── Permisos
├── Configuración
└── Auditoría
```

### Reglas

Toda la gestión técnica y de seguridad debe vivir aquí.

---

# Menú Final Esperado

```text
Dashboard

Operaciones

Inventario

Compras

Finanzas

Contabilidad

RRHH

DGII

Reportes

Administración
```

---

# Estructura Recomendada en Flutter

```text
lib/
└── modules/
    ├── dashboard/
    │
    ├── operaciones/
    │   ├── clients/
    │   ├── sales/
    │   ├── invoices/
    │   └── quotations/
    │
    ├── inventario/
    │   ├── products/
    │   ├── ingredients/
    │   ├── recipes/
    │   └── kardex/
    │
    ├── compras/
    │   ├── purchases/
    │   ├── suppliers/
    │   └── accounts_payable/
    │
    ├── finanzas/
    │   ├── cash/
    │   ├── banks/
    │   ├── expenses/
    │   └── accounts_receivable/
    │
    ├── contabilidad/
    │
    ├── rrhh/
    │
    ├── dgii/
    │
    ├── reportes/
    │
    └── administracion/
```

---

# Beneficios Esperados

1. Menos opciones visibles en el menú principal.
2. Navegación más intuitiva para el usuario.
3. Escalabilidad para futuras funcionalidades.
4. Separación clara entre procesos de negocio.
5. Mejor organización para arquitectura modular en Flutter.
6. Preparación para evolucionar desde un sistema de restaurante hacia un ERP completo.
