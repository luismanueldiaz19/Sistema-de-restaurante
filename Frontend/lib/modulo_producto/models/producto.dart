import 'dart:convert';
import 'package:sistema_restaurante/utils/normalize.dart';

import 'categoria_model.dart';
import 'marca_model.dart';
import 'impuesto_model.dart';
import 'unidad_medida_model.dart';
import 'receta.dart';

List<Producto> productoFromJson(String str) =>
    List<Producto>.from(json.decode(str).map((x) => Producto.fromJson(x)));

String productoToJson(List<Producto> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class Producto {
  final int? id;
  final String? nombre;
  final String? codigo;
  final String? descripcion;

  final int? categoriaId;
  final int? marcaId;
  final int? unidadMedidaId;
  final int? impuestoId;

  final CategoriaModel? categoria;
  final MarcaModel? marca;
  final UnidadMedidaModel? unidadMedida;
  final ImpuestoModel? impuesto;

  final String? tipoProducto;
  final String? tipoContable;

  final double? precioVenta;
  final double? costo;

  final bool? manejaInventario;
  final double? stockActual;
  final double? stockMinimo;

  final int? cuentaIngresoId;
  final int? cuentaInventarioId;
  final int? cuentaCostoId;
  final int? cuentaGastoId;

  final bool? activo;
  final int? createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<Receta>? recetas;

  late final String searchIndex;

  Producto({
    this.id,
    this.nombre,
    this.codigo,
    this.descripcion,
    this.categoriaId,
    this.marcaId,
    this.unidadMedidaId,
    this.impuestoId,
    this.categoria,
    this.marca,
    this.unidadMedida,
    this.impuesto,
    this.tipoProducto,
    this.tipoContable,
    this.precioVenta,
    this.costo,
    this.manejaInventario,
    this.stockActual,
    this.stockMinimo,
    this.cuentaIngresoId,
    this.cuentaInventarioId,
    this.cuentaCostoId,
    this.cuentaGastoId,
    this.activo,
    this.createdBy,
    this.createdAt,
    this.updatedAt,
    this.recetas,
  }) {
    // Código que se ejecuta después de crear el objeto.
    // Inicializa el índice de búsqueda del producto
    // utilizando los campos relevantes normalizados.
    searchIndex = TextNormalizer.normalizar(
      [
        nombre ?? '',
        codigo ?? '',
        categoria?.nombre ?? '',
        marca?.nombre ?? '',
        unidadMedida?.abreviatura ?? '',
        impuesto?.nombre ?? '',
      ].join(" "),
    );
  }

  factory Producto.fromJson(Map<String, dynamic> json) => Producto(
    id: json["id"],
    nombre: json["nombre"],
    codigo: json["codigo"],
    descripcion: json["descripcion"],
    categoriaId: json["categoria_id"],
    marcaId: json["marca_id"],
    unidadMedidaId: json["unidad_medida_id"],
    impuestoId: json["impuesto_id"],
    categoria: json["categoria"] != null
        ? CategoriaModel.fromJson(json["categoria"])
        : null,
    marca: json["marca"] != null ? MarcaModel.fromJson(json["marca"]) : null,
    unidadMedida: json["unidad_medida"] != null ? UnidadMedidaModel.fromJson(json["unidad_medida"]) : null,
    impuesto: json["impuesto"] != null
        ? ImpuestoModel.fromJson(json["impuesto"])
        : null,
    tipoProducto: json["tipo_producto"] ?? 'PRODUCTO',
    tipoContable: json["tipo_contable"] ?? 'INVENTARIO',
    precioVenta: json["precio_venta"]?.toDouble(),
    costo: json["costo"]?.toDouble(),
    manejaInventario:
        json["maneja_inventario"] == 1 || json["maneja_inventario"] == true,
    stockActual: json["stock_actual"]?.toDouble(),
    stockMinimo: json["stock_minimo"]?.toDouble(),
    cuentaIngresoId: json["cuenta_ingreso_id"],
    cuentaInventarioId: json["cuenta_inventario_id"],
    cuentaCostoId: json["cuenta_costo_id"],
    cuentaGastoId: json["cuenta_gasto_id"],
    activo: json["activo"] == 1 || json["activo"] == true,
    createdBy: json["created_by"],
    createdAt: json["created_at"] == null
        ? null
        : DateTime.parse(json["created_at"]),
    updatedAt: json["updated_at"] == null
        ? null
        : DateTime.parse(json["updated_at"]),
    recetas: json["recetas"] == null 
        ? [] 
        : List<Receta>.from(json["recetas"].map((x) => Receta.fromJson(x))),
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "nombre": nombre,
    "codigo": codigo,
    "descripcion": descripcion,
    "categoria_id": categoriaId,
    "marca_id": marcaId,
    "unidad_medida_id": unidadMedidaId,
    "impuesto_id": impuestoId,
    "tipo_producto": tipoProducto,
    "tipo_contable": tipoContable,
    "precio_venta": precioVenta,
    "costo": costo,
    "maneja_inventario": manejaInventario,
    "stock_actual": stockActual,
    "stock_minimo": stockMinimo,
    "cuenta_ingreso_id": cuentaIngresoId,
    "cuenta_inventario_id": cuentaInventarioId,
    "cuenta_costo_id": cuentaCostoId,
    "cuenta_gasto_id": cuentaGastoId,
    "activo": activo,
    "created_by": createdBy,
  };
}
