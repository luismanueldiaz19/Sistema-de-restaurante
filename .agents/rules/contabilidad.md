# Regla de Integración del Motor Contable Automático

Siempre que el usuario solicite **"incluir la contabilidad"**, **"generar asiento contable"**, o se desarrolle una funcionalidad de transacciones financieras (compras, ventas, pagos a proveedores, cobros a clientes, nómina, ajustes de inventario o gastos):

1. **Documento de Referencia Obligatorio:**
   Consulta y sigue la arquitectura descrita en:
   `backend/app/Modules/Contabilidad/README.md`

2. **Cero Código Duro (Zero Hardcoding):**
   NUNCA quemes IDs ni códigos de cuentas contables fijas (ej. jamás escribir `cuenta_id = 4`). Todas las cuentas deben resolverse dinámicamente mediante `ConfiguracionContableService` y la tabla `configuraciones_contables`.

3. **Uso del DTO y Servicio Central:**
   Para generar asientos automáticos desde cualquier módulo de negocio, instancia `RegistrarAsientoDTO` y llama a:
   `app(ContabilidadService::class)->registrarAsientoAuto($dto);`

4. **Validación de Partida Doble:**
   Todo asiento generado debe cumplir con la partida doble:
   $\sum \text{Débitos} = \sum \text{Créditos}$
   La transacción atómica de base de datos se revierte si no cuadra.

5. **Cuentas de Detalle:**
   Toda cuenta asociada a una configuración debe ser cuenta de detalle (`permite_movimiento == true`).
