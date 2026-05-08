import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sistema_restaurante/modulo_cliente/models/cliente.dart';
import 'package:sistema_restaurante/modulo_cliente/providers/cliente_admin_provider.dart';
import 'package:sistema_restaurante/utils/helpers.dart';

import '../../model/comprobante.dart';
import '../../model/detalle.dart';
import '../../model/factura.dart';
import '../../providers/auth_provider.dart';
import '../../providers/auth_state.dart';
import '../../providers/factura_provider.dart';
import '../../repositories/repo_comprobante.dart';
import '../../widgets/buscador_dialog.dart';
import 'widgets/buscador_cliente_dialog.dart';
import 'widgets/productos_widget.dart';

class CrearFacturaPage extends ConsumerStatefulWidget {
  const CrearFacturaPage({super.key});

  @override
  ConsumerState<CrearFacturaPage> createState() => _CrearFacturaPageState();
}

class _CrearFacturaPageState extends ConsumerState<CrearFacturaPage> {
  final clienteCtrl = TextEditingController();
  final ncfCtrl = TextEditingController();
  final fechaCtrl = TextEditingController();
  final fechaVencCtrl = TextEditingController();
  List<Comprobante> listComprobante = [];
  Comprobante? comprobanteSeleccionado;
  Cliente? clientePicked;
  ComprobanteRepository comprobanteRepository = ComprobanteRepository();
  Future fetComprobante(String token) async {
    print('buscando comprobante');
    final value = await comprobanteRepository.getComprabante(token);
    listComprobante = value;
    setState(() {});
  }

  // List<Map<String, dynamic>> detalles = [];

  // void agregarProducto() {
  //   setState(() {
  //     detalles.add({
  //       "descripcion": "",
  //       "unidad_medida": "",
  //       "cantidad": 1,
  //       "precio": 0.0,
  //       "descuento": 0.0,
  //       "descuento_porcentaje": 0.0,
  //     });
  //   });
  // }

  void guardarFactura(AuthState auth) async {
    if (clientePicked == null ||
        comprobanteSeleccionado == null ||
        fechaCtrl.text.isEmpty ||
        fechaVencCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error de factura'),
          duration: Duration(seconds: 1),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final provider = ref.read(facturaProvider.notifier);
    final providerState = ref.read(facturaProvider);

    final factura = Factura(
      clienteId: clientePicked!.id,
      ncf: comprobanteSeleccionado!.id.toString(),
      ncfSecuenciaId: comprobanteSeleccionado!.id,
      fechaEmision: DateTime.parse(fechaCtrl.text),
      fechaVencimiento: DateTime.parse(fechaVencCtrl.text),
      userId: auth.user!.id,
      detalles: articulosPicked.map((d) {
        return Detalle(
          descripcion: d['descripcion'],
          unidadMedida: d['unidad_medida'],
          cantidad: d['cantidad'],
          precio: d['precio'],
          descuento: d['descuento'],
          descuentoPorcentaje: d['descuento_porcentaje'],
        );
      }).toList(),
    );

    await provider.crearFactura(factura, auth.token!);

    final updatedState = ref.read(facturaProvider);

    if (updatedState.facturaId != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Factura creada ID: ${updatedState.facturaId}")),
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(updatedState.error ?? "Error")));
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((value) {
      fechaCtrl.text = DateTime.now().toString();
      final auth = ref.read(authProvider);
      fetComprobante(auth.token!);
    });
  }

  final List<Map<String, dynamic>> articulosPicked = [];

  List<Map<String, dynamic>> productos = [
    {
      "descripcion": "Pizza",
      "unidad_medida": "UNIT",
      "precio": 200.0,
      "stock": 10,
    },
    {
      "descripcion": "Hamburguesa",
      "unidad_medida": "UNIT",
      "precio": 150.0,
      "stock": 5,
    },
  ];
  @override
  Widget build(BuildContext context) {
    final provider = ref.watch(facturaProvider);
    final providerCliente = ref.watch(clienteAdminProvider);
    final auth = ref.watch(authProvider);
    Widget formularioEntrada() {
      return Column(
        children: [
          textFieldWidgetUI(
            label: 'Buscar Cliente',
            controller: clienteCtrl,
            readOnly: true,
            onTap: () async {
              final cliente = await showDialog<Cliente>(
                context: context,
                barrierDismissible: true,
                builder: (context) {
                  return BuscadorClienteDialog(
                    clientes: providerCliente.clientes,
                  );
                },
              );

              if (cliente != null) {
                clienteCtrl.text = cliente.nombre ?? '';
                clientePicked = cliente;

                setState(() {});
              }
            },
          ),

          if (listComprobante.isNotEmpty)
            SizedBox(
              width: 250,
              child: DropdownButtonFormField<Comprobante>(
                value: comprobanteSeleccionado,
                items: listComprobante.map((c) {
                  return DropdownMenuItem<Comprobante>(
                    value: c,
                    child: Text("${c.prefijo}${c.tipo} - ${c.nombre}"),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    comprobanteSeleccionado = value!;
                    ncfCtrl.text = comprobanteSeleccionado!.nombre;
                  });
                },
                decoration: InputDecoration(
                  labelText: "Tipo de comprobante",
                  border: OutlineInputBorder(),
                ),
              ),
            ),

          textFieldWidgetUI(
            controller: fechaCtrl,
            readOnly: true,
            label: 'Fecha emisión',
            onTap: () async {
              await pickSingleDate(context, (fecha) {
                fechaCtrl.text = fecha;
              });
            },
          ),

          textFieldWidgetUI(
            controller: fechaVencCtrl,
            label: 'Fecha vencimiento',
            readOnly: true,
            onTap: () async {
              await pickSingleDate(context, (fecha) {
                fechaVencCtrl.text = fecha;
              });
            },
          ),
        ],
      );
    }

    final style = Theme.of(context).textTheme;
    Widget formularioArticulos() {
      return StatefulBuilder(
        builder: (context, setState) {
          return Container(
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Text(
                    "Artículos seleccionados",
                    style: style.titleLarge,
                  ),
                ),

                Expanded(
                  child: ListView.separated(
                    itemCount: articulosPicked.length,
                    itemBuilder: (context, index) {
                      final item = articulosPicked[index];

                      double total =
                          (item["cantidad"] * item["precio"]) -
                          item["descuento"];

                      return Container(
                        decoration: BoxDecoration(color: Colors.white),
                        margin: EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Column(
                            children: [
                              // 🔹 Descripción + eliminar
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      item["descripcion"],
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.delete, color: Colors.red),
                                    onPressed: () {
                                      setState(() {
                                        articulosPicked.removeAt(index);
                                      });
                                    },
                                  ),
                                ],
                              ),

                              // 🔹 Cantidad y precio

                              // 🔹 Descuento
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      decoration: InputDecoration(
                                        labelText: "Cantidad",
                                      ),
                                      keyboardType: TextInputType.number,
                                      controller: TextEditingController(
                                        text: item["cantidad"].toString(),
                                      ),
                                      onChanged: (value) {
                                        item["cantidad"] =
                                            double.tryParse(value) ?? 0;
                                      },
                                    ),
                                  ),
                                  SizedBox(width: 10),
                                  Expanded(
                                    child: TextField(
                                      decoration: InputDecoration(
                                        labelText: "Precio",
                                      ),
                                      keyboardType: TextInputType.number,
                                      controller: TextEditingController(
                                        text: item["precio"].toString(),
                                      ),
                                      onChanged: (value) {
                                        item["precio"] =
                                            double.tryParse(value) ?? 0;
                                      },
                                    ),
                                  ),
                                  SizedBox(width: 10),
                                  Expanded(
                                    child: TextField(
                                      decoration: InputDecoration(
                                        labelText: "Descuento",
                                      ),
                                      keyboardType: TextInputType.number,
                                      controller: TextEditingController(
                                        text: item["descuento"].toString(),
                                      ),
                                      onChanged: (value) {
                                        item["descuento"] =
                                            double.tryParse(value) ?? 0;
                                      },
                                    ),
                                  ),
                                  SizedBox(width: 10),
                                  Expanded(
                                    child: TextField(
                                      decoration: InputDecoration(
                                        labelText: "% Descuento",
                                      ),
                                      keyboardType: TextInputType.number,
                                      controller: TextEditingController(
                                        text: item["descuento_porcentaje"]
                                            .toString(),
                                      ),
                                      onChanged: (value) {
                                        item["descuento_porcentaje"] =
                                            double.tryParse(value) ?? 0;
                                      },
                                    ),
                                  ),
                                ],
                              ),

                              SizedBox(height: 10),

                              // 🔹 Total
                              Align(
                                alignment: Alignment.centerRight,
                                child: Text(
                                  "Total: \$${total.toStringAsFixed(2)}",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    separatorBuilder: (context, index) {
                      return const Divider(color: Colors.black54);
                    },
                  ),
                ),
                if (articulosPicked.isNotEmpty)
                  CustomLoginButton(
                    height: 50,
                    width: double.maxFinite,
                    onPressed: () {
                      guardarFactura(auth);
                    },
                    text: 'Crear Factura',
                  ),
                if (articulosPicked.isNotEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(0.0),
                      child: TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: Text('Cancelar'),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: Text("Crear Factura")),
      body: LayoutBuilder(
        builder: (context, constraints) {
          double width = constraints.maxWidth;
          double height = MediaQuery.of(context).size.height;

          const double minWidth = 350;
          int columns = (width / minWidth).floor();

          if (columns >= 3) {
            // 🖥️ PANTALLA GRANDE → 3 COLUMNAS
            return SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: Row(
                children: [
                  SizedBox(
                    height: height * 0.7,
                    width: minWidth,
                    child: formularioEntrada(),
                  ),

                  SizedBox(
                    height: height * 0.7,
                    width: minWidth,
                    child: ProductosWidget(
                      productos: productos,
                      articulos: articulosPicked,
                      onUpdate: () => setState(() {}),
                    ),
                  ),
                  SizedBox(
                    height: height * 0.7,
                    width: minWidth,
                    child: formularioArticulos(),
                  ),
                ],
              ),
            );
          } else {
            return Center(child: Text('Pantalla no disponible'));
          }
        },
      ),
    );
  }
}
