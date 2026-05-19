# 📚 Módulo Contable de Compras

## 🎯 Objetivo
Registrar de forma automática y consistente todas las operaciones de compras de un restaurante, clasificando entre inventario, activos fijos, gastos operativos, servicios básicos y servicios profesionales, aplicando correctamente ITBIS y retenciones según la normativa contable.

---

## 🔄 Proceso de registros contables

### 1. Compra de mercancía (ej. pan, carne, refrescos)
- **Inventario (1.x)** → Débito  
- **Cuentas por pagar proveedor (2.x)** → Crédito  
- **ITBIS por pagar (2.0.6)** → Crédito  

---

### 2. Compra de activos fijos (ej. licuadora, nevera)
- **Activos fijos (1.x)** → Débito  
- **Cuentas por pagar proveedor (2.x)** → Crédito  
- **ITBIS por pagar (2.0.6)** → Crédito  

---

### 3. Gastos operativos (ej. papel de oficina, detergente)
- **Gastos operativos (6.x)** → Débito  
- **Cuentas por pagar proveedor (2.x)** → Crédito  
- **ITBIS por pagar (2.0.6)** → Crédito  

---

### 4. Servicios básicos (ej. luz, agua, teléfono)
- **Gastos de servicios (6.x)** → Débito  
- **Banco (1.x)** → Crédito  
- **Nota:** No llevan ITBIS  

---

### 5. Servicios profesionales (ej. albañil, consultor)
- **Gastos de servicios profesionales (6.x)** → Débito  
- **Cuentas por pagar proveedor (2.x)** → Crédito  
- **ITBIS por pagar (2.0.6)** → Crédito  
- **Retenciones ISR/ITBIS** → Débito en cuentas de retenciones  

---

### 6. Materiales de construcción / remodelación (ej. cemento, pintura)
- **Gastos de remodelación (6.x)** o **Activos en mejora (1.x)** → Débito  
- **Cuentas por pagar proveedor (2.x)** → Crédito  
- **ITBIS por pagar (2.0.6)** → Crédito  

---

## ✅ Reglas generales
- Clasificar automáticamente el tipo de compra según el ítem registrado.  
- Aplicar ITBIS solo a bienes y servicios gravados.  
- Excluir ITBIS en servicios básicos (ej. electricidad, agua).  
- Aplicar retenciones en servicios profesionales según normativa.  
- Generar asiento contable en cada compra con trazabilidad para auditoría.  
