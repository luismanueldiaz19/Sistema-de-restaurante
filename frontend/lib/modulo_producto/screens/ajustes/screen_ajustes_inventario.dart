import 'package:flutter/material.dart';
import 'tabs/categoria_tab.dart';
import 'tabs/marca_tab.dart';
import 'tabs/unidad_medida_tab.dart';
import 'tabs/impuesto_tab.dart';

class ScreenAjustesInventario extends StatelessWidget {
  const ScreenAjustesInventario({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Configuración de Catálogos'),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(icon: Icon(Icons.category), text: 'Categorías'),
              Tab(icon: Icon(Icons.branding_watermark), text: 'Marcas'),
              Tab(icon: Icon(Icons.straighten), text: 'Unidades de Medida'),
              Tab(icon: Icon(Icons.percent), text: 'Impuestos'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            CategoriaTab(),
            MarcaTab(),
            UnidadMedidaTab(),
            ImpuestoTab(),
          ],
        ),
      ),
    );
  }
}
