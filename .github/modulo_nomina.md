# Módulo de Nómina (Payroll) - Especificación Técnica y Contable

Este documento detalla la arquitectura, lógica contable y requerimientos técnicos para la implementación del módulo de nómina, actuando bajo el rol de **Contador Profesional** y **Senior Developer**.

## 1. Visión General del Módulo
El objetivo es automatizar el cálculo de salarios, retenciones legales y beneficios marginales, garantizando el cumplimiento de las leyes dominicanas (TSS, ISR, Código de Trabajo).

---

## 2. Lógica Contable (Cumplimiento Legal RD)

### A. Tesorería de la Seguridad Social (TSS)
Cálculo de aportes obligatorios basados en el Salario Cotizable (hasta el tope salarial vigente).

| Concepto | Empleado (%) | Empleador (%) |
| :--- | :--- | :--- |
| **Seguro Familiar de Salud (SFS)** | 3.04% | 7.09% |
| **Administradora de Fondos de Pensiones (AFP)** | 2.87% | 7.10% |
| **Seguro de Riesgos Laborales (SRL)** | 0% | Variable (0.75% - 1.55%) |
| **INFOTEP** | 0% | 1.00% |

### B. Impuesto Sobre la Renta (ISR - Personas Físicas)
Aplicación de la escala progresiva mensual de la DGII (Valores referenciales 2024):
1. **Renta neta gravable** = Salario Bruto - Retenciones TSS.
2. **Escala Mensual**:
   - Hasta RD$ 34,685.00: **Exento**.
   - RD$ 34,685.01 a RD$ 52,027.42: **15%** del excedente de 34,685.00.
   - RD$ 52,027.43 a RD$ 72,260.25: **RD$ 2,601.36 + 20%** del excedente de 52,027.42.
   - Más de RD$ 72,260.26: **RD$ 6,648.00 + 25%** del excedente de 72,260.25.

---

## 3. Arquitectura Técnica (SOLID Compliance)

Siguiendo las reglas del proyecto en `.github/regla.md`, el módulo se dividirá en:

### A. Modelos (`lib/models/`)
- `EmpleadoModel`: Datos personales, cargo, salario base, tipo de contrato.
- `NominaModel`: Cabecera del periodo (Fecha inicio/fin, estado, totales).
- `NominaDetalleModel`: Registro individual por empleado (Salario bruto, desgloses TSS/ISR, neto a cobrar).
- `DeduccionModel`: Préstamos, seguros complementarios, ausencias.

### B. Servicios (`lib/services/`)
- `NominaService`: Lógica pura de cálculo (Pure functions para TSS e ISR).
- `EmpleadoService`: CRUD de empleados.
- `ExportService`: Generación de archivos para TSS (SUIR) y comprobantes PDF.

### C. Providers (`lib/providers/`)
- `NominaProvider`: Gestión del estado de la nómina actual, histórico y carga de datos.
- `CalculadoraNominaProvider`: Estado temporal para simulaciones de salarios.

---

## 4. Estructura de Datos (PostgreSQL)

```sql
-- Tabla de Empleados
CREATE TABLE empleados (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(100),
    cedula VARCHAR(15) UNIQUE,
    salario_base DECIMAL(12,2),
    fecha_ingreso DATE,
    cargo_id INT,
    estado BOOLEAN DEFAULT TRUE
);

-- Detalle de Nómina
CREATE TABLE nomina_detalles (
    id SERIAL PRIMARY KEY,
    nomina_id INT REFERENCES nominas(id),
    empleado_id INT REFERENCES empleados(id),
    salario_bruto DECIMAL(12,2),
    afp_empleado DECIMAL(12,2),
    sfs_empleado DECIMAL(12,2),
    isr_retencion DECIMAL(12,2),
    otros_descuentos DECIMAL(12,2),
    salario_neto DECIMAL(12,2)
);
```

---

## 5. UI/UX Strategy

### Pantallas Principales:
1. **Dashboard de Nómina**: Resumen de costos operativos (Salarios + Carga impositiva patronal).
2. **Generación de Periodo**: Selector de fechas, carga masiva de novedades (horas extras, faltas).
3. **Ficha de Empleado**: Configuración de salario y deducciones fijas.
4. **Visor de Volante**: Vista previa profesional del comprobante de pago.

### Componentes Reutilizables:
- `StatCard`: Para mostrar AFP/SFS/ISR de forma visual.
- `NominaTable`: Tabla optimizada con scroll horizontal para desgloses.
- `CalculationBadge`: Indicador visual de si el cálculo está validado o pendiente.

---

## 6. Seguridad y Accesos

Para proteger la sensibilidad de los datos salariales, el acceso a este módulo estará restringido mediante roles:

### Roles con Acceso:
1. **Administrador**: Acceso total (Configuración, edición, eliminación y reportes).
2. **Contador**: Acceso total a la gestión de nómina, pero restringido en configuraciones globales del sistema.
3. **Auxiliar Contable**: Acceso de lectura y creación de borradores de nómina. No puede autorizar pagos finales.

### Implementación:
- Se utilizará un `PermissionMiddleware` o validación en el `Drawer` principal para ocultar/mostrar el módulo según el rol del usuario autenticado.

---

## 7. Próximos Pasos

1. **Gestión de Permisos**: Definir los roles de 'Contable' y 'Auxiliar Contable' en el sistema de autenticación.
2. **Definición de Entidades**: Creación de los modelos en Dart con soporte para JSON.
3. **Implementación de Lógica Core**: Crear la clase `NominaCalculator` con pruebas unitarias para validar TSS/ISR.
4. **Backend Integration**: Endpoints para persistir los periodos de nómina.
5. **UI**: Desarrollo de la pantalla de gestión de empleados.
