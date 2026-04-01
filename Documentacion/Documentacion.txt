🧠 PROMPT PARA SISTEMA DE RESTAURANTE CON BUFFET (FLUTTER + LARAVEL)

Eres un arquitecto de software senior especializado en desarrollo de sistemas empresariales. Necesito que diseñes y desarrolles un sistema completo para la gestión de un restaurante enfocado en servicios de buffet para eventos.

El sistema debe estar dividido en:

Frontend: Flutter (Web/Mobile/Desktop)
Backend: Laravel (API RESTful)
Base de datos: PostgreSQL
🎯 OBJETIVO DEL SISTEMA

El sistema debe permitir gestionar operaciones completas de un restaurante con enfoque en eventos tipo buffet, incluyendo cotizaciones, facturación, gastos, cuentas y nómina.

🧩 MÓDULOS PRINCIPALES
1. 👥 Clientes
CRUD de clientes
Información: nombre, teléfono, dirección, RNC/Cédula
Historial de eventos y facturas
2. 🍽️ Buffet / Eventos
Crear eventos:
Cliente
Fecha del evento
Cantidad de personas
Ubicación
Tipo de buffet
Selección de menú (platos, bebidas, extras)
Costo por persona
Cálculo automático del total
3. 🧾 Cotizaciones de Buffet
Crear cotización:
Cliente
Evento asociado
Lista de productos/servicios
Precio por persona
Estados:
Pendiente
Aprobada
Rechazada
Conversión de cotización a factura
4. 🧾 Facturación
Facturación de buffet y ventas normales
Generación de comprobantes (NCF opcional)
Cálculo de impuestos (ITBIS)
Estados:
Pendiente
Pagada
Parcial
Relación con clientes
5. 📦 Inventario / Materiales
Productos:
Ingredientes
Materiales
Control de entradas y salidas
Consumo automático por evento (opcional)
Stock mínimo
6. 💸 Gastos
Registro de gastos:
Compra de materiales
Gastos operativos
Categorías de gasto
Relación con proveedores
7. 🏢 Proveedores
CRUD de proveedores
Relación con compras y cuentas por pagar
8. 📉 Cuentas por Pagar
Registro automático desde compras/gastos
Pagos parciales o completos
Estado de deuda
9. 📈 Cuentas por Cobrar
Generadas desde facturas
Registro de pagos de clientes
Balance pendiente
10. 💵 Nómina de Empleados
CRUD de empleados
Tipos de pago:
Semanal
Quincenal
Cálculo de sueldo:
Base
Horas trabajadas
Bonos
Deducciones
Registro de pagos
11. 👤 Usuarios y Seguridad
Autenticación (JWT o Sanctum)
Roles y permisos
Auditoría de acciones
🧱 ESTRUCTURA DEL BACKEND (LARAVEL)
API REST con rutas organizadas por módulo
Uso de controladores, servicios y repositorios
Validaciones con FormRequest
Middleware de autenticación
Relación entre modelos (Eloquent ORM)
🧱 ESTRUCTURA DEL FRONTEND (FLUTTER)
Arquitectura limpia (Clean Architecture)
Manejo de estado con Riverpod
Pantallas:
Dashboard
Clientes
Eventos
Cotizaciones
Facturación
Inventario
Gastos
Cuentas
Nómina
Formularios reutilizables
Tablas dinámicas
Consumo de API con HTTP/Dio
🗄️ BASE DE DATOS (POSTGRESQL)

Diseñar todas las tablas con:

Relaciones (FK)
Índices
Auditoría (created_at, updated_at, user_id)

Tablas clave:

clientes
eventos
cotizaciones
facturas
detalle_factura
productos
inventario_movimientos
gastos
proveedores
cuentas_por_pagar
cuentas_por_cobrar
empleados
nomina
⚙️ FUNCIONALIDADES AVANZADAS (OPCIONAL)
Generación de PDF (cotización, factura)
Reportes:
Ventas
Gastos
Utilidad por evento
Dashboard con métricas
Notificaciones
Modo offline (Flutter)
📌 RESULTADO ESPERADO

Quiero que generes:

Estructura completa del proyecto (Frontend + Backend)
Modelos y migraciones en Laravel
Endpoints API
Ejemplo de consumo desde Flutter
Diseño de base de datos
Flujo completo:
Cotización → Evento → Factura → Pago