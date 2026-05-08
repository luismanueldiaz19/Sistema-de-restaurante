import 'package:flutter/material.dart';
import '../../models/producto_provisional.dart';
import '../../../utils/helpers.dart'; // 🔥 Importar helpers

class ProductosWidget extends StatefulWidget {
  const ProductosWidget({
    super.key,
    required this.productos,
    required this.articulos,
    required this.onUpdate,
    this.onProductTap,
  });
  final List<ProductoProvisional> productos;
  final List<Map<String, dynamic>> articulos;
  final VoidCallback onUpdate;
  final Function(ProductoProvisional)? onProductTap;

  @override
  State createState() => _ProductosWidgetState();
}

class _ProductosWidgetState extends State<ProductosWidget> {
  TextEditingController searchController = TextEditingController();
  List<ProductoProvisional> productosFiltrados = [];

  Map<int, int> cantidades = {};

  @override
  void initState() {
    super.initState();
    productosFiltrados = widget.productos;
  }

  void agregarProducto(ProductoProvisional producto, int cantidad) {
    int existingIndex = widget.articulos.indexWhere(
      (a) => a["descripcion"] == producto.descripcion,
    );

    if (existingIndex != -1) {
      widget.articulos[existingIndex]["cantidad"] += cantidad;
    } else {
      widget.articulos.add({
        "descripcion": producto.descripcion,
        "unidad_medida": producto.unidadMedida,
        "cantidad": cantidad,
        "precio": producto.precio,
        "descuento": 0.0,
        "descuento_porcentaje": 0.0,
      });
    }

    widget.onUpdate(); // 🔥 notifica al padre
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // 🔍 BUSCADOR
          Padding(
            padding: const EdgeInsets.all(10),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: "Buscar producto...",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  productosFiltrados = widget.productos
                      .where(
                        (p) => p.descripcion.toLowerCase().contains(
                          value.toLowerCase(),
                        ),
                      )
                      .toList();
                });
              },
            ),
          ),

          // 📦 LISTA
          Expanded(
            child: ListView.builder(
              itemCount: productosFiltrados.length,
              itemBuilder: (context, index) {
                final producto = productosFiltrados[index];

                cantidades[index] ??= 1;

                return Card(
                  child: ListTile(
                    title: Text(producto.descripcion),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Stock: ${producto.stock}"),
                        Text("Precio: ${formatCurrency(producto.precio)}"),
                      ],
                    ),

                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // ➖
                        IconButton(
                          icon: Icon(Icons.remove),
                          onPressed: () {
                            setState(() {
                              if (cantidades[index]! > 1) {
                                cantidades[index] = cantidades[index]! - 1;
                              }
                            });
                          },
                        ),

                        Text("${cantidades[index]}"),

                        // ➕
                        IconButton(
                          icon: Icon(Icons.add),
                          onPressed: () {
                            setState(() {
                              cantidades[index] = cantidades[index]! + 1;
                            });
                          },
                        ),

                        // 🛒 AGREGAR
                        IconButton(
                          icon: const Icon(
                            Icons.add_shopping_cart,
                            color: Colors.green,
                          ),
                          onPressed: () {
                            int cantidad = cantidades[index]!;

                            // Notificar al nuevo sistema
                            if (widget.onProductTap != null) {
                              widget.onProductTap!(producto);
                            }

                            agregarProducto(producto, cantidad);

                            setState(() {
                              cantidades[index] = 1;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
