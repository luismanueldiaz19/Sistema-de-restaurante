import 'dart:convert';

import 'package:sistema_restaurante/facturacion/models/factura_item.dart';
import 'package:sistema_restaurante/services/api_services.dart';
import 'package:sistema_restaurante/utils/constants.dart';

import '../../modulo_compras/models/proveedor.dart';

class OrdenCompraService {
  final ApiService _api = ApiService();
  final String _baseUrl = "$hostName/api";

  Future<Map<String, dynamic>> crearOrdenCompra({
    required Proveedor proveedor,
    required List<FacturaItem> items,
    required String token,
    String nota = "",
    int diasValidez = 15,
  }) async {
    try {
      final payload = {
        "proveedor_id": proveedor.id,
        "nota": nota,
        "fecha_emision": DateTime.now().toIso8601String(),
        "fecha_vencimiento": DateTime.now()
            .add(Duration(days: diasValidez))
            .toIso8601String(),
        "detalles": items
            .map(
              (item) => {
                "producto_id": int.tryParse(item.id),
                "descripcion": item.descripcion,
                "cantidad": item.cantidad,
                "precio": item.precio,
                "descuento_porcentaje": item.descuentoPorcentaje,
                "descuento": item.montoDescuento,
                "impuesto_incluido": true,
                "tasa_impuesto": item.itbisPorcentaje,
              },
            )
            .toList(),
      };

      final response = await _api.post(
        "$_baseUrl/ordenes-compras",
        payload,
        token: token,
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {"success": true, "data": data};
      } else {
        return {
          "success": false,
          "message": data['message'] ?? "Error desconocido",
        };
      }
    } catch (e) {
      return {"success": false, "message": "Error de conexión: $e"};
    }
  }

  Future<Map<String, dynamic>> getHistorial({
    required String token,
    Map<String, String>? filters,
  }) async {
    try {
      String query = "";
      if (filters != null && filters.isNotEmpty) {
        query =
            "?" + filters.entries.map((e) => "${e.key}=${e.value}").join("&");
      }

      final response = await _api.get(
        "$_baseUrl/ordenes-compras$query",
        token: token,
      );
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          "success": true,
          "data": data['data'],
          "resumen": data['resumen'],
        };
      } else {
        return {
          "success": false,
          "message": data['message'] ?? "Error al obtener órdenes de compra",
        };
      }
    } catch (e) {
      return {"success": false, "message": "Error de conexión: $e"};
    }
  }

  Future<Map<String, dynamic>> getOrdenCompra({
    required String id,
    required String token,
  }) async {
    try {
      final response = await _api.get(
        "$_baseUrl/ordenes-compras/$id",
        token: token,
      );
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {"success": true, "data": data['data']};
      } else {
        return {
          "success": false,
          "message": data['message'] ?? "Error al obtener orden de compra",
        };
      }
    } catch (e) {
      return {"success": false, "message": "Error de conexión: $e"};
    }
  }

  Future<Map<String, dynamic>> updateEstado({
    required String id,
    required String estado,
    required String token,
  }) async {
    try {
      final response = await _api.patch(
        "$_baseUrl/ordenes-compras/$id/estado",
        {"estado": estado},
        token: token,
      );
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {"success": true, "message": data['message']};
      } else {
        return {
          "success": false,
          "message": data['message'] ?? "Error al actualizar",
        };
      }
    } catch (e) {
      return {"success": false, "message": "Error de conexión: $e"};
    }
  }

  Future<Map<String, dynamic>> convertirACompra({
    required String ordenId,
    required String proveedorId,
    required String numeroFactura,
    required String ncf,
    required String tipoCompra,
    required String fechaCompra,
    required List<dynamic> detalles,
    required String token,
  }) async {
    try {
      final payload = {
        "proveedor_id": int.tryParse(proveedorId),
        "numero_factura_proveedor": numeroFactura,
        "ncf": ncf,
        "fecha_compra": fechaCompra,
        "tipo_compra": tipoCompra,
        "detalles": detalles
            .map(
              (item) => {
                "producto_id": item.productoId,
                "descripcion": item.descripcion,
                "cantidad": double.tryParse(item.cantidad ?? "0") ?? 0,
                "costo_unitario": double.tryParse(item.precio ?? "0") ?? 0,
                "impuesto_monto": double.tryParse(item.itbis ?? "0") ?? 0,
              },
            )
            .toList(),
      };

      final response = await _api.post(
        "$_baseUrl/compras",
        payload,
        token: token,
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Change state to RECIBIDA
        await updateEstado(id: ordenId, estado: 'RECIBIDA', token: token);
        return {"success": true, "message": "Compra registrada con éxito"};
      } else {
        return {
          "success": false,
          "message":
              data['error'] ?? data['message'] ?? "Error al registrar compra",
        };
      }
    } catch (e) {
      return {"success": false, "message": "Error de conexión: $e"};
    }
  }
}
