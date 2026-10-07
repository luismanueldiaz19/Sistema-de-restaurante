# Módulo Caja, Turnos y Cierre - Reglas de negocio

## Objetivo
Gestionar operaciones de caja, control de cajeros, turnos, arqueo, conteo físico y conciliación diaria.

---

## Conceptos

### Caja
Punto de cobro físico o virtual.

Ejemplos:
- Caja 1
- Caja 2
- POS principal

---

### Cajero
Usuario autorizado para:
- abrir caja
- facturar
- cobrar
- cerrar caja

---

### Turno
Bloque horario de operación.

Ejemplos:
- mañana 08:00 - 16:00
- noche 16:00 - 00:00

---

### Sesión de caja
Período entre apertura y cierre.

Estados:
- abierta
- cerrada

Una sesión pertenece a:
- caja
- cajero
- turno

---

## Flujo operativo

1. abrir caja
2. registrar ventas/cobros
3. registrar retiros/ingresos
4. cierre caja
5. arqueo
6. conciliación

---

## Apertura caja

Datos requeridos:
- caja_id
- cajero_id
- turno_id
- monto_inicial

Validaciones:
- no permitir doble apertura

```php
if ($sesionCajaAbierta) {
   throw new Exception('Ya existe caja abierta');
}