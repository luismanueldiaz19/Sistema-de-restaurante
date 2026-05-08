import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/factura_item.dart';
import '../../../modulo_cliente/models/cliente.dart';
import '../../../model/comprobante.dart';

class FacturacionService {
  final String baseUrl = "http://127.0.0.1:8000/api";

  Future<Map<String, dynamic>> crearFactura({
    required Cliente cliente,
    required Comprobante comprobante,
    required List<FacturaItem> items,
    required String token,
    required int userId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/facturas"),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          "cliente_id": cliente.id,
          "ncf_secuencia_id": comprobante.id,
          "user_id": userId,
          "fecha_emision": DateTime.now().toIso8601String(),
          "fecha_vencimiento": DateTime.now().add(const Duration(days: 30)).toIso8601String(),
          "detalles": items.map((item) => {
            "descripcion": item.descripcion,
            "cantidad": item.cantidad,
            "precio": item.precio,
            "itbis": item.montoItbis,
            "descuento": item.montoDescuento,
            "subtotal": item.subtotal,
            "total": item.total,
          }).toList(),
        }),
      );

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {"success": true, "data": data};
      } else {
        return {"success": false, "message": data['message'] ?? "Error desconocido"};
      }
    } catch (e) {
      return {"success": false, "message": "Error de conexión: $e"};
    }
  }
}
