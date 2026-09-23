# API de Autenticación (v2)

Esta documentación describe cómo obtener un **Token de Acceso** para consumir los demás módulos de la API v2.

---

## 1. Iniciar Sesión (Obtener Token)
**POST** `/api/v2/login`

Verifica las credenciales de un usuario y retorna un Token de acceso permanente (Sanctum) que debe enviarse en los headers de peticiones posteriores.

### Cuerpo JSON Esperado
```json
{
  "email": "usuario@ejemplo.com",
  "password": "password123"
}
```

### Respuesta (200 OK)
```json
{
  "status": true,
  "message": "Autenticación exitosa",
  "data": {
    "user": {
      "id": 1,
      "name": "Administrador",
      "email": "usuario@ejemplo.com"
    },
    "token": "1|abc123def456ghi789..."
  }
}
```
*El valor de `token` es el que debes guardar y enviar como `Authorization: Bearer <token>`.*

### Respuesta de Error (401 Unauthorized)
```json
{
  "status": false,
  "message": "Credenciales incorrectas"
}
```

---

## 2. Cerrar Sesión (Revocar Token)
**POST** `/api/v2/logout`

Invalida el token enviado en la petición actual. No afecta a otros tokens del mismo usuario.

> [!IMPORTANT]  
> Requiere estar autenticado. Debes enviar el token actual en los headers.

### Respuesta (200 OK)
```json
{
  "status": true,
  "message": "Sesión cerrada correctamente (Token revocado)"
}
```
