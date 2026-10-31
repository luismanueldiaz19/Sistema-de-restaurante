# 🧪 Guía de Calidad (QA) para la Creación de Tests

Esta guía establece el estándar de oro para escribir tests dentro del proyecto. 
Está diseñada bajo la perspectiva de un perfil de **Quality Assurance (QA)**, 
buscando asegurar que las pruebas no solo validen el código, sino que documenten
 y protejan las reglas de negocio del sistema.

---

## 1. Nomenclatura Descriptiva
El nombre de la función de prueba debe explicar claramente qué comportamiento 
o regla de negocio se está validando.
- **Formato recomendado:** `test_debe_[comportamiento_esperado]_[bajo_qué_condición]`
- **Ejemplo Correcto:** `test_debe_devolver_el_costo_de_un_producto_con_plato()`
- **Ejemplo Incorrecto:** `test_costo_plato()`

---

## 2. Documentación del Caso de Negocio
Antes de escribir cualquier línea de código, el test debe incluir 
un bloque documental claro. Este bloque sirve para que cualquier desarrollador,
tester manual, o gerente de producto entienda 
la prueba sin necesidad de saber leer código.

**Estructura Obligatoria:**
```php
// =============================================================
// CASO DE NEGOCIO
// =============================================================
// El cliente compra una Pizza.
// La Pizza tiene:
// 2 Harinas   (RD$50)
// 3 Quesos    (RD$100)
// El sistema debe calcular: (2 x 50) + (3 x 100)
// Resultado esperado: RD$400
// =============================================================
```

---

## 3. El Patrón "AAA" (Arrange, Act, Assert)
Todo test debe estar estrictamente dividido en tres pasos cronológicos, separados visualmente.

### 🟡 A. ARRANGE (Preparar el escenario)
Se define el estado inicial del sistema, creando los registros necesarios y las dependencias de la prueba.
- **Reglas QA:**
  - Usa siempre **Factories** (`Producto::factory()->create()`) para generar datos semilla. Nunca insertes usando arreglos en bruto (`DB::table(...)`) a menos que sea estrictamente necesario.
  - Asegúrate de importar los modelos al inicio del archivo (`use App\Models\Receta;`) para mantener el código limpio.
  - Define claramente los valores que afectarán el resultado de tu prueba (ej. establecer un costo específico para un ingrediente).

### 🔵 B. ACT (Ejecutar la acción)
Es el disparador de la prueba. Generalmente consta de una sola línea de código donde ejecutas la funcionalidad.
- **Reglas QA:**
  - Llama al Servicio, Controlador, o Ruta.
  - Guarda la salida en una variable clara como `$resultado` o `$response`.
  - No incluyas validaciones ni preparaciones adicionales en este bloque.

### 🟢 C. ASSERT (Verificar el resultado)
La confirmación de que la regla de negocio definida arriba se cumplió de forma idéntica.
- **Reglas QA:**
  - Comprueba la respuesta directa: `$this->assertEquals(400, $resultado);`
  - Si la acción altera el estado del sistema, comprueba la base de datos: `$this->assertDatabaseHas(...)`
  - La aserción debe coincidir con tu "Resultado esperado" del bloque documental.

---

## 4. Estándares y Buenas Prácticas
1. **Independencia Total:** Cada prueba debe poder ejecutarse de forma aislada. Jamás dependas de datos generados en un test anterior.
2. **RefreshDatabase:** Usa siempre el Trait `use RefreshDatabase;` en las clases de tests Feature para garantizar que la base de datos se limpia y restaura tras cada test.
3. **Mantenibilidad:** Si un test es demasiado largo y tiene más de 30 líneas de preparación (Arrange), probablemente estás probando demasiadas cosas a la vez, considera subdividirlo.
