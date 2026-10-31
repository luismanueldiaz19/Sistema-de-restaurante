# API de Clientes (v2)

Esta documentación describe el uso de los endpoints del módulo de Clientes en la API v2. Todas las rutas requieren un **Bearer Token** en los headers para su autorización.

---

## 1. Listar Clientes
**GET** `/api/v2/clientes`

Obtiene una lista paginada de clientes.

### Parámetros opcionales (Query)
- `per_page`: Número de resultados por página (por defecto 15).
- `search`: Texto para buscar por nombre, RNC/Cédula o email.

### Respuesta (200 OK)
```json
{
  "data": [
    {
      "id": 1,
      "nombre": "Juan Pérez",
      "rnc_cedula": "001-1234567-8",
      "email": "juan@example.com",
      "telefono": "809-555-1234",
      "direccion": "Calle Falsa 123",
      "tipo_cliente": "Fisico",
      "limite_credito": 50000.0,
      "saldo_actual": 0.0,
      "dias_credito": 15,
      "cuenta_contable": null,
      "descuento_fijo": 0.0,
      "activo": true,
      "notas": "Cliente preferencial",
      "created_at": "2023-01-01T10:00:00Z",
      "updated_at": "2023-01-01T10:00:00Z"
    }
  ],
  "links": { ... },
  "meta": { ... }
}
```

---

## 2. Crear Cliente
**POST** `/api/v2/clientes`

Crea un nuevo cliente.

### Cuerpo JSON Esperado
> [!NOTE]  
> El campo `tipo_cliente` solo permite los siguientes valores: `consumidor_final`, `credito`, `gubernamental`, `especial`.

```json
{
  "nombre": "Empresa ABC SRL",
  "rnc_cedula": "130-12345-6",
  "email": "contacto@empresaabc.com",
  "telefono": "809-555-9876",
  "tipo_cliente": "credito",
  "limite_credito": 100000.0,
  "dias_credito": 30,
  "activo": true
}
```

### Respuesta (201 Created)
```json
{
  "message": "Cliente creado exitosamente",
  "data": {
    "id": 2,
    "nombre": "Empresa ABC SRL",
    ...
  }
}
```

---

## 3. Obtener un Cliente
**GET** `/api/v2/clientes/{id}`

Obtiene los detalles de un cliente específico.

---

## 4. Actualizar Cliente
**PUT** `/api/v2/clientes/{id}`

Actualiza un cliente existente. Se pueden enviar solo los campos que se desean actualizar.

### Cuerpo JSON Esperado
```json
{
  "telefono": "809-555-0000",
  "limite_credito": 150000.0
}
```

### Respuesta (200 OK)
```json
{
  "message": "Cliente actualizado exitosamente",
  "data": { ... }
}
```

---

## 5. Eliminar Cliente
**DELETE** `/api/v2/clientes/{id}`

Elimina un cliente del sistema.

### Respuesta (200 OK)
```json
{
  "message": "Cliente eliminado exitosamente"
}
```
