import 'dart:convert';

List<Producto> productoFromJson(String str) =>
    List<Producto>.from(json.decode(str).map((x) => Producto.fromJson(x)));

String productoToJson(List<Producto> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class Producto {
  final int? id;
  final String? nombre;
  final String? codigo;
  final String? descripcion;
  final String? categoria;
  final String? tipoProducto;
  final String? unidadMedida;
  final double? precioVenta;
  final double? costo;
  final double? itbisPorcentaje;
  final bool? manejaInventario;
  final double? stockActual;
  final double? stockMinimo;
  final String? cuentaContableIngresos;
  final String? cuentaContableInventario;
  final String? cuentaContableCostos;
  final bool? activo;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Producto({
    this.id,
    this.nombre,
    this.codigo,
    this.descripcion,
    this.categoria,
    this.precioVenta,
    this.costo,
    this.itbisPorcentaje,
    this.manejaInventario,
    this.stockActual,
    this.stockMinimo,
    this.cuentaContableIngresos,
    this.cuentaContableInventario,
    this.cuentaContableCostos,
    this.activo,
    this.createdAt,
    this.updatedAt,
    this.unidadMedida,
    this.tipoProducto,
  });

  factory Producto.fromJson(Map<String, dynamic> json) => Producto(
    id: json["id"],
    nombre: json["nombre"],
    codigo: json["codigo"],
    descripcion: json["descripcion"],
    categoria: json["categoria"],
    tipoProducto: json["tipo_producto"] ?? 'VENTA_DIRECTA',
    unidadMedida: json["unidad_medida"],
    precioVenta: json["precio_venta"]?.toDouble(),
    costo: json["costo"]?.toDouble(),
    itbisPorcentaje: json["itbis_porcentaje"]?.toDouble(),
    manejaInventario:
        json["maneja_inventario"] == 1 || json["maneja_inventario"] == true,
    stockActual: json["stock_actual"]?.toDouble(),
    stockMinimo: json["stock_minimo"]?.toDouble(),
    cuentaContableIngresos: json["cuenta_contable_ingresos"],
    cuentaContableInventario: json["cuenta_contable_inventario"],
    cuentaContableCostos: json["cuenta_contable_costos"],
    activo: json["activo"] == 1 || json["activo"] == true,
    createdAt: json["created_at"] == null
        ? null
        : DateTime.parse(json["created_at"]),
    updatedAt: json["updated_at"] == null
        ? null
        : DateTime.parse(json["updated_at"]),
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "nombre": nombre,
    "codigo": codigo,
    "descripcion": descripcion,
    "categoria": categoria,
    "tipo_producto": tipoProducto,
    "unidad_medida": unidadMedida,
    "precio_venta": precioVenta,
    "costo": costo,
    "itbis_porcentaje": itbisPorcentaje,
    "maneja_inventario": manejaInventario,
    "stock_actual": stockActual,
    "stock_minimo": stockMinimo,
    "cuenta_contable_ingresos": cuentaContableIngresos,
    "cuenta_contable_inventario": cuentaContableInventario,
    "cuenta_contable_costos": cuentaContableCostos,
    "activo": activo,
  };
}
