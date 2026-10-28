import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../palletes/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../utils/formatter_number.dart';
import '../providers/producto_provider.dart';

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}

class ScreenPreviewImportProductos extends ConsumerStatefulWidget {
  final String filename;
  final Map<String, dynamic> previewData;

  const ScreenPreviewImportProductos({
    super.key,
    required this.filename,
    required this.previewData,
  });

  @override
  ConsumerState<ScreenPreviewImportProductos> createState() =>
      _ScreenPreviewImportProductosState();
}

class _ScreenPreviewImportProductosState
    extends ConsumerState<ScreenPreviewImportProductos> {
  late List<Map<String, dynamic>> _filas;
  String _filtroEstado = 'TODOS';
  String _searchQuery = '';
  final TextEditingController _searchCtrl = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final rawFilas = widget.previewData['filas'] as List? ?? [];
    _filas = rawFilas.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  int get _totalFilas => _filas.length;
  int get _listosCount => _filas.where((f) => f['estado'] == 'LISTO').length;
  int get _duplicadosCount => _filas
      .where(
        (f) =>
            f['estado'] == 'DUPLICADO_BD' || f['estado'] == 'DUPLICADO_ARCHIVO',
      )
      .length;
  int get _erroresCount => _filas.where((f) => f['estado'] == 'ERROR').length;
  int get _seleccionadosCount => _filas
      .where((f) => f['seleccionado'] == true && f['estado'] == 'LISTO')
      .length;

  List<Map<String, dynamic>> get _filasFiltradas {
    return _filas.where((f) {
      if (_filtroEstado == 'LISTO' && f['estado'] != 'LISTO') return false;
      if (_filtroEstado == 'DUPLICADO' &&
          f['estado'] != 'DUPLICADO_BD' &&
          f['estado'] != 'DUPLICADO_ARCHIVO') {
        return false;
      }
      if (_filtroEstado == 'ERROR' && f['estado'] != 'ERROR') return false;

      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toUpperCase();
        final nombre = (f['nombre'] ?? '').toString().toUpperCase();
        final codigo = (f['codigo'] ?? '').toString().toUpperCase();
        if (!nombre.contains(q) && !codigo.contains(q)) return false;
      }
      return true;
    }).toList();
  }

  void _revalidarFilasLocalmente() {
    final productosEnBd = ref.read(productoProvider).productos;
    final nombresBd = productosEnBd
        .map((p) => (p.nombre ?? '').trim().toUpperCase())
        .where((n) => n.isNotEmpty)
        .toSet();
    final codigosBd = productosEnBd
        .map((p) => (p.codigo ?? '').trim().toUpperCase())
        .where((c) => c.isNotEmpty)
        .toSet();

    final nombresVistos = <String, int>{};
    final codigosVistos = <String, int>{};

    setState(() {
      for (final fila in _filas) {
        final numFila = fila['fila'] as int? ?? 0;
        final nombre = (fila['nombre'] ?? '')
            .toString()
            .trim()
            .toUpperCase()
            .replaceAll(RegExp(r'\s+'), ' ');
        fila['nombre'] = nombre;

        String codigo = (fila['codigo'] ?? '').toString().trim().toUpperCase();
        if (codigo.isEmpty) {
          codigo = _generarSkuLocal(nombre, codigosVistos.keys.toSet());
          fila['codigo'] = codigo;
          fila['codigo_autogenerado'] = true;
        }

        final precio = double.tryParse(fila['precio_venta'].toString()) ?? -1;
        final costo = double.tryParse(fila['costo'].toString()) ?? -1;
        final stock = double.tryParse(fila['stock_actual'].toString()) ?? -1;
        final stockMin = double.tryParse(fila['stock_minimo'].toString()) ?? -1;

        final msgs = <String>[];
        String nuevoEstado = 'LISTO';

        if (nombre.isEmpty) {
          msgs.add('El nombre es obligatorio.');
        }
        if (precio < 0) {
          msgs.add('Precio de venta inválido (< 0).');
        }
        if (costo < 0) {
          msgs.add('Costo inválido (< 0).');
        }
        if (stock < 0) {
          msgs.add('Cantidad de stock no puede ser negativa.');
        }
        if (stockMin < 0) {
          msgs.add('Stock mínimo no puede ser negativo.');
        }

        if (msgs.isNotEmpty) {
          nuevoEstado = 'ERROR';
        } else if (nombresVistos.containsKey(nombre)) {
          nuevoEstado = 'DUPLICADO_ARCHIVO';
          msgs.add(
            'Nombre repetido en este archivo (fila ${nombresVistos[nombre]}).',
          );
        } else if (codigosVistos.containsKey(codigo)) {
          nuevoEstado = 'DUPLICADO_ARCHIVO';
          msgs.add(
            'Código repetido en este archivo (fila ${codigosVistos[codigo]}).',
          );
        } else if (nombresBd.contains(nombre)) {
          nuevoEstado = 'DUPLICADO_BD';
          msgs.add('Ya existe un producto con este nombre en el sistema.');
        } else if (codigosBd.contains(codigo)) {
          nuevoEstado = 'DUPLICADO_BD';
          msgs.add('Ya existe un producto con este código en el sistema.');
        }

        if (nombre.isNotEmpty && !nombresVistos.containsKey(nombre)) {
          nombresVistos[nombre] = numFila;
        }
        if (codigo.isNotEmpty && !codigosVistos.containsKey(codigo)) {
          codigosVistos[codigo] = numFila;
        }

        final estadoAnterior = fila['estado'];
        fila['estado'] = nuevoEstado;
        fila['mensajes'] = msgs;

        if (nuevoEstado != 'LISTO') {
          fila['seleccionado'] = false;
        } else if (estadoAnterior != 'LISTO' && nuevoEstado == 'LISTO') {
          fila['seleccionado'] = true;
        }
      }
    });
  }

  String _generarSkuLocal(String nombre, Set<String> ocupados) {
    final words = nombre
        .replaceAll(RegExp(r'[^A-Z0-9\s]'), '')
        .split(' ')
        .where((w) => w.isNotEmpty)
        .toList();
    String prefix = 'PRD';
    if (words.length == 1) {
      prefix = words[0].substring(0, words[0].length < 3 ? words[0].length : 3);
    } else if (words.length == 2) {
      prefix =
          '${words[0].substring(0, words[0].length < 2 ? 1 : 2)}${words[1][0]}';
    } else if (words.length >= 3) {
      prefix = '${words[0][0]}${words[1][0]}${words[2][0]}';
    }
    prefix = prefix.padRight(3, 'X');

    int seq = ocupados.length + 1;
    while (true) {
      final cand = '$prefix-${seq.toString().padLeft(4, '0')}';
      if (!ocupados.contains(cand)) return cand;
      seq++;
    }
  }

  void _mostrarDialogoEditarFila(Map<String, dynamic> fila) {
    final nombreCtrl = TextEditingController(
      text: (fila['nombre'] ?? '').toString().toUpperCase(),
    );
    final codigoCtrl = TextEditingController(
      text: (fila['codigo'] ?? '').toString().toUpperCase(),
    );
    final stockCtrl = TextEditingController(
      text: (fila['stock_actual'] ?? 0).toString(),
    );
    final stockMinCtrl = TextEditingController(
      text: (fila['stock_minimo'] ?? 0).toString(),
    );
    final costoCtrl = TextEditingController(
      text: (fila['costo'] ?? 0).toString(),
    );
    final precioCtrl = TextEditingController(
      text: (fila['precio_venta'] ?? 0).toString(),
    );
    bool manejaInv = fila['maneja_inventario'] == true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Editar Fila #${fila['fila']}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.azulOscuro,
                        ),
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close, size: 18),
                      ),
                    ],
                  ),
                  const Divider(height: 16),
                  _buildCompactInput(
                    label: 'Nombre del Producto (UPPERCASE) *',
                    controller: nombreCtrl,
                    inputFormatters: [UpperCaseTextFormatter()],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _buildCompactInput(
                          label: 'Código / SKU (vacío = auto)',
                          controller: codigoCtrl,
                          inputFormatters: [UpperCaseTextFormatter()],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: OutlinedButton.icon(
                          onPressed: () {
                            final ocupados = _filas
                                .map((e) => (e['codigo'] ?? '').toString())
                                .toSet();
                            codigoCtrl.text = _generarSkuLocal(
                              nombreCtrl.text,
                              ocupados,
                            );
                          },
                          icon: const Icon(Icons.autorenew, size: 14),
                          label: const Text(
                            'Generar',
                            style: TextStyle(fontSize: 11),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _buildCompactInput(
                          label: 'Cantidad (Stock Inicial)',
                          controller: stockCtrl,
                          isNumeric: true,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildCompactInput(
                          label: 'Stock Mínimo',
                          controller: stockMinCtrl,
                          isNumeric: true,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _buildCompactInput(
                          label: 'Costo Unitario',
                          controller: costoCtrl,
                          isNumeric: true,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildCompactInput(
                          label: 'Precio de Venta *',
                          controller: precioCtrl,
                          isNumeric: true,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Switch(
                        value: manejaInv,
                        activeThumbColor: AppColors.primary,
                        onChanged: (v) => setDialogState(() => manejaInv = v),
                      ),
                      const Text(
                        'Maneja Inventario',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text(
                          'Cancelar',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: () {
                          fila['nombre'] = nombreCtrl.text.trim().toUpperCase();
                          fila['codigo'] = codigoCtrl.text.trim().toUpperCase();
                          fila['codigo_autogenerado'] = false;
                          fila['stock_actual'] =
                              double.tryParse(stockCtrl.text) ?? 0.0;
                          fila['stock_minimo'] =
                              double.tryParse(stockMinCtrl.text) ?? 0.0;
                          fila['costo'] =
                              double.tryParse(costoCtrl.text) ?? 0.0;
                          fila['precio_venta'] =
                              double.tryParse(precioCtrl.text) ?? 0.0;
                          fila['maneja_inventario'] = manejaInv;

                          Navigator.pop(ctx);
                          _revalidarFilasLocalmente();
                        },
                        icon: const Icon(Icons.check, size: 15),
                        label: const Text(
                          'Aplicar y Revalidar',
                          style: TextStyle(fontSize: 12),
                        ),
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
          ),
        ),
      ),
    );
  }

  Widget _buildCompactInput({
    required String label,
    required TextEditingController controller,
    bool isNumeric = false,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          height: 36,
          child: TextField(
            controller: controller,
            keyboardType: isNumeric
                ? const TextInputType.numberWithOptions(decimal: true)
                : TextInputType.text,
            inputFormatters:
                inputFormatters ??
                (isNumeric
                    ? [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))]
                    : null),
            style: const TextStyle(fontSize: 12),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 8,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _confirmarSubida() async {
    final seleccionados = _filas
        .where((f) => f['seleccionado'] == true && f['estado'] == 'LISTO')
        .toList();

    if (seleccionados.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No hay productos válidos seleccionados para importar.',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final token = ref.read(authProvider).token!;
      final result = await ref
          .read(productoProvider.notifier)
          .confirmImportProductos(seleccionados, token);

      if (!mounted) return;
      setState(() => _isSubmitting = false);

      final data = result['data'] as Map<String, dynamic>? ?? {};
      final creados = data['creados'] ?? seleccionados.length;
      final omitidos = data['omitidos'] ?? 0;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Importación exitosa: $creados productos creados${omitidos > 0 ? ', $omitidos omitidos' : ''}.',
          ),
          backgroundColor: Colors.green.shade700,
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final filasVisibles = _filasFiltradas;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: AppColors.azulOscuro),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Confirmar Importación de Productos',
              style: TextStyle(
                color: AppColors.azulOscuro,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
            Text(
              'Archivo: ${widget.filename}  •  Todos los nombres en UPPERCASE',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            child: OutlinedButton.icon(
              onPressed: _revalidarFilasLocalmente,
              icon: const Icon(Icons.fact_check_outlined, size: 15),
              label: const Text(
                'Revalidar Todo',
                style: TextStyle(fontSize: 12),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.azulOscuro,
                side: BorderSide(color: Colors.grey.shade300),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16, top: 10, bottom: 10),
            child: ElevatedButton.icon(
              onPressed: (_isSubmitting || _seleccionadosCount == 0)
                  ? null
                  : _confirmarSubida,
              icon: _isSubmitting
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.cloud_upload_outlined, size: 16),
              label: Text(
                _isSubmitting
                    ? 'Subiendo...'
                    : 'Confirmar y Subir ($_seleccionadosCount)',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade700,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Top Summary & Filters Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              children: [
                _buildKpiFilterChip(
                  label: 'Todos ($_totalFilas)',
                  value: 'TODOS',
                  color: AppColors.azulOscuro,
                  icon: Icons.list_alt_rounded,
                ),
                const SizedBox(width: 8),
                _buildKpiFilterChip(
                  label: 'Listos ($_listosCount)',
                  value: 'LISTO',
                  color: Colors.green.shade700,
                  icon: Icons.check_circle_outline,
                ),
                const SizedBox(width: 8),
                _buildKpiFilterChip(
                  label: 'Duplicados ($_duplicadosCount)',
                  value: 'DUPLICADO',
                  color: Colors.orange.shade800,
                  icon: Icons.copy_all_rounded,
                ),
                const SizedBox(width: 8),
                _buildKpiFilterChip(
                  label: 'Con Errores ($_erroresCount)',
                  value: 'ERROR',
                  color: Colors.red.shade700,
                  icon: Icons.error_outline,
                ),
                const Spacer(),
                SizedBox(
                  width: 240,
                  height: 34,
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (v) => setState(() => _searchQuery = v),
                    style: const TextStyle(fontSize: 12),
                    decoration: InputDecoration(
                      hintText: 'Filtrar por nombre o código...',
                      hintStyle: const TextStyle(fontSize: 11.5),
                      prefixIcon: const Icon(Icons.search, size: 16),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 14),
                              onPressed: () {
                                _searchCtrl.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 0,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Table Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: DataTable2(
                    headingRowHeight: 36,
                    dataRowHeight: 42,
                    columnSpacing: 12,
                    horizontalMargin: 12,
                    minWidth: 1050,
                    headingRowColor: WidgetStateProperty.all(
                      const Color(0xFFF1F5F9),
                    ),
                    headingTextStyle: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                      color: AppColors.azulOscuro,
                    ),
                    columns: [
                      DataColumn2(
                        fixedWidth: 42,
                        label: Checkbox(
                          visualDensity: VisualDensity.compact,
                          value:
                              _listosCount > 0 &&
                              _seleccionadosCount == _listosCount,
                          onChanged: (val) {
                            setState(() {
                              for (final f in _filas) {
                                if (f['estado'] == 'LISTO') {
                                  f['seleccionado'] = val ?? false;
                                }
                              }
                            });
                          },
                        ),
                      ),
                      const DataColumn2(fixedWidth: 50, label: Text('FILA')),
                      const DataColumn2(fixedWidth: 135, label: Text('ESTADO')),
                      const DataColumn2(
                        fixedWidth: 120,
                        label: Text('CÓDIGO SKU'),
                      ),
                      const DataColumn2(
                        size: ColumnSize.L,
                        label: Text('NOMBRE DEL PRODUCTO (UPPERCASE)'),
                      ),
                      const DataColumn2(
                        fixedWidth: 110,
                        label: Text('CATEGORÍA'),
                      ),
                      const DataColumn2(fixedWidth: 95, label: Text('TIPO')),
                      const DataColumn2(
                        fixedWidth: 85,
                        numeric: true,
                        label: Text('CANTIDAD'),
                      ),
                      const DataColumn2(
                        fixedWidth: 80,
                        numeric: true,
                        label: Text('MÍNIMO'),
                      ),
                      const DataColumn2(
                        fixedWidth: 95,
                        numeric: true,
                        label: Text('COSTO'),
                      ),
                      const DataColumn2(
                        fixedWidth: 105,
                        numeric: true,
                        label: Text('PRECIO VENTA'),
                      ),
                      const DataColumn2(
                        fixedWidth: 85,
                        label: Text('ACCIONES'),
                      ),
                    ],
                    rows: filasVisibles.map((fila) {
                      final esListo = fila['estado'] == 'LISTO';
                      final seleccionado =
                          fila['seleccionado'] == true && esListo;
                      final mensajes =
                          (fila['mensajes'] as List?)
                              ?.map((e) => e.toString())
                              .toList() ??
                          [];
                      final autoGen = fila['codigo_autogenerado'] == true;

                      return DataRow2(
                        color: WidgetStateProperty.resolveWith((_) {
                          if (!esListo) {
                            return Colors.red.withValues(alpha: 0.03);
                          }
                          return null;
                        }),
                        cells: [
                          DataCell(
                            Checkbox(
                              visualDensity: VisualDensity.compact,
                              value: seleccionado,
                              onChanged: esListo
                                  ? (val) {
                                      setState(() {
                                        fila['seleccionado'] = val ?? false;
                                      });
                                    }
                                  : null,
                            ),
                          ),
                          DataCell(
                            Text(
                              '#${fila['fila']}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.black54,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          DataCell(
                            _buildStatusBadge(
                              fila['estado']?.toString() ?? 'LISTO',
                              mensajes,
                            ),
                          ),
                          DataCell(
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  child: Text(
                                    (fila['codigo'] ?? '').toString(),
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      fontFamily: 'monospace',
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (autoGen) ...[
                                  const SizedBox(width: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                      vertical: 1,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.teal.withValues(
                                        alpha: 0.12,
                                      ),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      'AUTO',
                                      style: TextStyle(
                                        fontSize: 8.5,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.teal,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          DataCell(
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  (fila['nombre'] ?? '')
                                      .toString()
                                      .toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.azulOscuro,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (mensajes.isNotEmpty)
                                  Text(
                                    mensajes.join(' '),
                                    style: TextStyle(
                                      fontSize: 9.5,
                                      color: esListo
                                          ? Colors.orange.shade800
                                          : Colors.red.shade700,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                              ],
                            ),
                          ),
                          DataCell(
                            Text(
                              '${fila['categoria_nombre'] ?? 'General'} (${fila['unidad_abrev'] ?? 'UND'})',
                              style: const TextStyle(fontSize: 11),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          DataCell(
                            Text(
                              (fila['tipo_producto'] ?? 'PRODUCTO').toString(),
                              style: const TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          DataCell(
                            Text(
                              FormatterNumber.formatNumber(
                                (fila['stock_actual'] as num?)?.toDouble() ?? 0,
                              ),
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: ((fila['stock_actual'] as num?) ?? 0) > 0
                                    ? Colors.green.shade700
                                    : Colors.black87,
                              ),
                            ),
                          ),
                          DataCell(
                            Text(
                              FormatterNumber.formatNumber(
                                (fila['stock_minimo'] as num?)?.toDouble() ?? 0,
                              ),
                              style: const TextStyle(fontSize: 11),
                            ),
                          ),
                          DataCell(
                            Text(
                              FormatterNumber.formatCurrency(
                                (fila['costo'] as num?)?.toDouble() ?? 0,
                              ),
                              style: const TextStyle(fontSize: 11),
                            ),
                          ),
                          DataCell(
                            Text(
                              FormatterNumber.formatCurrency(
                                (fila['precio_venta'] as num?)?.toDouble() ?? 0,
                              ),
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          DataCell(
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  visualDensity: VisualDensity.compact,
                                  tooltip: 'Editar fila',
                                  icon: const Icon(
                                    Icons.edit_outlined,
                                    size: 16,
                                    color: AppColors.azulOscuro,
                                  ),
                                  onPressed: () =>
                                      _mostrarDialogoEditarFila(fila),
                                ),
                                IconButton(
                                  visualDensity: VisualDensity.compact,
                                  tooltip: 'Quitar de la lista',
                                  icon: Icon(
                                    Icons.delete_outline,
                                    size: 16,
                                    color: Colors.red.shade400,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _filas.remove(fila);
                                    });
                                    _revalidarFilasLocalmente();
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiFilterChip({
    required String label,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    final isSelected = _filtroEstado == value;
    return InkWell(
      onTap: () => setState(() => _filtroEstado = value),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? color : color.withValues(alpha: 0.25),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: isSelected ? Colors.white : color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: isSelected ? Colors.white : color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String estado, List<String> mensajes) {
    Color color;
    String texto;
    IconData icon;

    switch (estado) {
      case 'LISTO':
        color = Colors.green.shade700;
        texto = 'LISTO';
        icon = Icons.check_circle_outline;
        break;
      case 'DUPLICADO_BD':
        color = Colors.orange.shade800;
        texto = 'YA EXISTE EN BD';
        icon = Icons.warning_amber_rounded;
        break;
      case 'DUPLICADO_ARCHIVO':
        color = Colors.amber.shade900;
        texto = 'REPETIDO EXCEL';
        icon = Icons.copy_all_rounded;
        break;
      default:
        color = Colors.red.shade700;
        texto = 'ERROR';
        icon = Icons.error_outline;
    }

    final badge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              texto,
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w800,
                color: color,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );

    if (mensajes.isEmpty) return badge;
    return Tooltip(message: mensajes.join('\n'), child: badge);
  }
}
