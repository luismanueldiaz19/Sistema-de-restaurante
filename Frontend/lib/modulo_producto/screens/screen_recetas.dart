import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:data_table_2/data_table_2.dart';
import '../../palletes/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_loading.dart';
import '../models/producto.dart';
import '../models/receta.dart';
import '../providers/producto_provider.dart';
import '../providers/receta_provider.dart';
import '../../widgets/buscador_dialog.dart';

class ScreenRecetas extends ConsumerStatefulWidget {
  const ScreenRecetas({super.key});

  @override
  ConsumerState<ScreenRecetas> createState() => _ScreenRecetasState();
}

class _ScreenRecetasState extends ConsumerState<ScreenRecetas> {
  List<Producto> _productosConRecetas = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final auth = ref.read(authProvider);
    final results = await ref
        .read(recetaProvider.notifier)
        .loadProductosConRecetas(auth.token!);
    if (mounted) {
      setState(() {
        _productosConRecetas = results;
        _isLoading = false;
      });
    }
  }

  void _showRecetaDialog(Producto producto) async {
    final auth = ref.read(authProvider);
    // Ensure we have all products loaded so we can pick Materia Prima
    if (ref.read(productoProvider).productos.isEmpty) {
      await ref.read(productoProvider.notifier).loadProductos(auth.token!);
    }

    final result = await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ConfigurarRecetaDialog(producto: producto),
    );

    if (result == true) {
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CustomLoading(text: "Cargando Platos y Combos...")),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          "Configuración de Recetas",
          style: TextStyle(
            color: AppColors.azulOscuro,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.azulOscuro),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Selecciona un Plato o Combo para configurar sus ingredientes. Al vender estos productos, se descontará automáticamente el inventario de la Materia Prima asignada.",
              style: TextStyle(color: Colors.blueGrey),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: DataTable2(
                    columnSpacing: 12,
                    horizontalMargin: 12,
                    headingRowColor: MaterialStateProperty.all(
                      Colors.grey.shade50,
                    ),
                    columns: const [
                      DataColumn2(
                        label: Text(
                          "CÓDIGO",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        fixedWidth: 100,
                      ),
                      DataColumn2(
                        label: Text(
                          "PLATO / COMBO",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataColumn2(
                        label: Text(
                          "TIPO",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        fixedWidth: 120,
                      ),
                      DataColumn2(
                        label: Text(
                          "INGREDIENTES",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        numeric: true,
                        fixedWidth: 100,
                      ),
                      DataColumn2(
                        label: Text(
                          "ACCIONES",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        fixedWidth: 100,
                      ),
                    ],
                    rows: _productosConRecetas.map((p) {
                      return DataRow2(
                        cells: [
                          DataCell(
                            Text(
                              p.codigo ?? '--',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blueGrey,
                              ),
                            ),
                          ),
                          DataCell(Text(p.nombre ?? '')),
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                p.tipoProducto ?? '',
                                style: const TextStyle(
                                  color: Colors.blue,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          DataCell(
                            Text(
                              '${p.recetas?.length ?? 0} items',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          DataCell(
                            IconButton(
                              icon: const Icon(
                                Icons.settings,
                                color: Colors.indigo,
                              ),
                              onPressed: () => _showRecetaDialog(p),
                              tooltip: 'Configurar Receta',
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ConfigurarRecetaDialog extends ConsumerStatefulWidget {
  final Producto producto;
  const ConfigurarRecetaDialog({super.key, required this.producto});

  @override
  ConsumerState<ConfigurarRecetaDialog> createState() =>
      _ConfigurarRecetaDialogState();
}

class _ConfigurarRecetaDialogState
    extends ConsumerState<ConfigurarRecetaDialog> {
  List<Receta> _recetaLines = [];
  List<Producto> _materiaPrima = [];

  @override
  void initState() {
    super.initState();
    _recetaLines = List.from(widget.producto.recetas ?? []);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final todos = ref.read(productoProvider).productos;
      setState(() {
        _materiaPrima = todos
            .where(
              (p) =>
                  p.tipoProducto == 'MATERIA_PRIMA' ||
                  p.tipoProducto == 'PRODUCTO',
            )
            .toList();
      });
    });
  }

  void _addLine() {
    setState(() {
      _recetaLines.add(
        Receta(
          productoId: widget.producto.id ?? 0,
          ingredienteProductoId: 0,
          cantidad: 1.0,
        ),
      );
    });
  }

  void _removeLine(int index) {
    setState(() {
      _recetaLines.removeAt(index);
    });
  }

  Future<void> _guardar() async {
    // Validate
    if (_recetaLines.any(
      (r) => r.ingredienteProductoId == 0 || r.cantidad <= 0,
    )) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Selecciona un ingrediente y cantidad válida para cada línea.',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final auth = ref.read(authProvider);
    final data = _recetaLines
        .map(
          (r) => {
            'ingrediente_producto_id': r.ingredienteProductoId,
            'cantidad': r.cantidad,
          },
        )
        .toList();

    final success = await ref
        .read(recetaProvider.notifier)
        .saveReceta(widget.producto.id.toString(), data, auth.token!);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Receta guardada exitosamente.'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    } else {
      final err = ref.read(recetaProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $err'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(recetaProvider);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Container(
        width: 600,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Receta: ${widget.producto.nombre}",
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.azulOscuro,
              ),
            ),
            const Divider(),
            const SizedBox(height: 10),
            if (_recetaLines.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Text(
                    "No hay ingredientes en esta receta.",
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 300),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _recetaLines.length,
                  itemBuilder: (ctx, i) {
                    final line = _recetaLines[i];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: InkWell(
                              onTap: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => BuscadorDialog<Producto>(
                                    items: _materiaPrima,
                                    itemLabel: (p) => "${p.nombre} (${p.unidadMedida?.abreviatura ?? 'UND'})",
                                    onSelected: (p) {
                                      setState(() {
                                        _recetaLines[i] = Receta(
                                          id: line.id,
                                          productoId: line.productoId,
                                          ingredienteProductoId: p.id ?? 0,
                                          cantidad: line.cantidad,
                                        );
                                      });
                                    },
                                  ),
                                );
                              },
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'Ingrediente',
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 12, // Adjusted for better height
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        line.ingredienteProductoId == 0
                                            ? 'Seleccionar...'
                                            : () {
                                                final p = _materiaPrima.firstWhere(
                                                  (p) => p.id == line.ingredienteProductoId,
                                                  orElse: () => Producto(nombre: 'Desconocido'),
                                                );
                                                return "${p.nombre} (${p.unidadMedida?.abreviatura ?? 'UND'})";
                                              }(),
                                        style: const TextStyle(fontSize: 14),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const Icon(Icons.arrow_drop_down, color: Colors.grey),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 1,
                            child: TextFormField(
                              initialValue: line.cantidad.toString(),
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Cantidad',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 0,
                                ),
                              ),
                              onChanged: (val) {
                                final qty = double.tryParse(val) ?? 0.0;
                                _recetaLines[i] = Receta(
                                  id: line.id,
                                  productoId: line.productoId,
                                  ingredienteProductoId:
                                      line.ingredienteProductoId,
                                  cantidad: qty,
                                );
                              },
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _removeLine(i),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 10),
            TextButton.icon(
              onPressed: _addLine,
              icon: const Icon(Icons.add),
              label: const Text("Agregar Ingrediente"),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Cancelar',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: state.isLoading ? null : _guardar,
                  icon: state.isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.save, size: 18),
                  label: const Text("Guardar Receta"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.azulOscuro,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
