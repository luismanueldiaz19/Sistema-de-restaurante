import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sistema_restaurante/modulo_cliente/models/cliente.dart';
import 'package:sistema_restaurante/modulo_cliente/providers/cliente_admin_provider.dart';
import 'package:sistema_restaurante/utils/helpers.dart';

import '../../model/comprobante.dart';
import '../../model/detalle.dart';
import '../../model/factura.dart';
import '../../providers/auth_provider.dart';
import '../../providers/factura_provider.dart';
import '../../repositories/repo_comprobante.dart';
import '../../widgets/buscador_dialog.dart';

class CrearFacturaPage extends StatefulWidget {
  const CrearFacturaPage({super.key});

  @override
  State createState() => _CrearFacturaPageState();
}

class _CrearFacturaPageState extends State<CrearFacturaPage> {
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

  List<Map<String, dynamic>> detalles = [];

  void agregarProducto() {
    setState(() {
      detalles.add({
        "descripcion": "",
        "unidad_medida": "",
        "cantidad": 1,
        "precio": 0.0,
        "descuento": 0.0,
        "descuento_porcentaje": 0.0,
      });
    });
  }

  void guardarFactura(AuthProvider auth) async {
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

    final provider = context.read<FacturaProvider>();

    final factura = Factura(
      clienteId: clientePicked!.id,
      ncf: comprobanteSeleccionado!.id.toString(),
      ncfSecuenciaId: comprobanteSeleccionado!.id,
      fechaEmision: DateTime.parse(fechaCtrl.text),
      fechaVencimiento: DateTime.parse(fechaVencCtrl.text),
      userId: auth.user!.id,
      detalles: detalles.map((d) {
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

    print(factura.toJson());

    await provider.crearFactura(factura, auth.token);

    if (provider.facturaId != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Factura creada ID: ${provider.facturaId}")),
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(provider.error ?? "Error")));
    }
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((value) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      fetComprobante(auth.token!);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FacturaProvider>();
    final providerCliente = context.watch<ClienteAdminProvider>();
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      appBar: AppBar(title: Text("Crear Factura")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            textFieldWidgetUI(
              label: 'Buscar Cliente',
              onTap: () async {
                showDialog(
                  context: context,
                  builder: (context) {
                    return BuscadorDialog(
                      items: Cliente.getUniqueNombre(providerCliente.clientes),
                      onSelected: (value) {
                        clienteCtrl.text = value;
                        clientePicked = providerCliente.clientes
                            .where(
                              (eleme) =>
                                  eleme.nombre!.toLowerCase() ==
                                  value.toLowerCase(),
                            )
                            .first;
                        // setFilterModulo(value);
                      },
                    );
                  },
                );
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

            SizedBox(height: 10),

            // 🔥 BOTÓN AGREGAR PRODUCTO
            ElevatedButton(
              onPressed: agregarProducto,
              child: Text("Agregar producto"),
            ),

            SizedBox(height: 10),

            // 🛒 LISTA DE DETALLES
            Expanded(
              child: ListView.builder(
                itemCount: detalles.length,
                itemBuilder: (context, index) {
                  final item = detalles[index];

                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        children: [
                          TextField(
                            decoration: InputDecoration(
                              labelText: "Descripción",
                            ),
                            onChanged: (val) => item['descripcion'] = val,
                          ),

                          TextField(
                            decoration: InputDecoration(labelText: "Unidad"),
                            onChanged: (val) => item['unidad_medida'] = val,
                          ),

                          TextField(
                            decoration: InputDecoration(labelText: "Cantidad"),
                            keyboardType: TextInputType.number,
                            onChanged: (val) =>
                                item['cantidad'] = int.tryParse(val) ?? 1,
                          ),

                          TextField(
                            decoration: InputDecoration(labelText: "Precio"),
                            keyboardType: TextInputType.number,
                            onChanged: (val) =>
                                item['precio'] = double.tryParse(val) ?? 0,
                          ),

                          TextField(
                            decoration: InputDecoration(labelText: "Descuento"),
                            keyboardType: TextInputType.number,
                            onChanged: (val) =>
                                item['descuento'] = double.tryParse(val) ?? 0,
                          ),

                          TextField(
                            decoration: InputDecoration(labelText: "% Desc"),
                            keyboardType: TextInputType.number,
                            onChanged: (val) => item['descuento_porcentaje'] =
                                double.tryParse(val) ?? 0,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // 🔥 BOTÓN GUARDAR
            provider.isLoading
                ? CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: () => guardarFactura(auth),
                    child: Text("Guardar Factura"),
                  ),
          ],
        ),
      ),
    );
  }
}
