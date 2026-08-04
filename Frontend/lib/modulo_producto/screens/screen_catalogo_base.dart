import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sistema_restaurante/utils/normalize.dart';

import '../../providers/auth_provider.dart';
import '../../widgets/card_moderno.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_loading.dart';
import '../services/catalogo_service.dart';
import '../../palletes/app_colors.dart';

class ScreenCatalogoBase extends ConsumerStatefulWidget {
  final String titulo;
  final String endpoint; // e.g. 'categorias', 'marcas', 'unidades-medida'

  const ScreenCatalogoBase({
    super.key,
    required this.titulo,
    required this.endpoint,
  });

  @override
  ConsumerState<ScreenCatalogoBase> createState() => _ScreenCatalogoBaseState();
}

class _ScreenCatalogoBaseState extends ConsumerState<ScreenCatalogoBase> {
  late CatalogoService api;
  List<dynamic> items = [];
  bool isLoading = false;

  Map<String, dynamic>? selectedItem;
  final TextEditingController _searchCtrl = TextEditingController();
  final TextEditingController _nombreCtrl = TextEditingController();
  final TextEditingController _descCtrl = TextEditingController();
  bool _activo = true;
  bool isSaving = false;

  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    api = CatalogoService(widget.endpoint);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    _nombreCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData({bool showLoading = true}) async {
    final queryText = TextNormalizer.normalizar(_searchCtrl.text.trim());

    if (showLoading) setState(() => isLoading = true);
    try {
      final token = ref.read(authProvider).token!;

      final result = await api.getAll(token, search: queryText);
      setState(() {
        items = result;
      });
    } catch (e) {
      _showSnack('Error al cargar datos: $e', isError: true);
    } finally {
      if (showLoading) setState(() => isLoading = false);
    }
  }

  void _onSearch(String val) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _loadData(showLoading: false);
    });
  }

  void _clearForm() {
    setState(() {
      selectedItem = null;
      _nombreCtrl.clear();
      _descCtrl.clear();
      _activo = true;
    });
  }

  void _selectItem(Map<String, dynamic> item) {
    setState(() {
      selectedItem = item;
      _nombreCtrl.text = item['nombre'] ?? '';

      // Unidades de Medida usa "abreviatura" en lugar de "descripcion"
      if (widget.endpoint == 'unidades-medida') {
        _descCtrl.text = item['abreviatura'] ?? '';
      } else {
        _descCtrl.text = item['descripcion'] ?? '';
      }

      _activo = item['activo'] == 1 || item['activo'] == true;
    });
  }

  Future<void> _save() async {
    if (_nombreCtrl.text.trim().isEmpty) {
      _showSnack('El nombre es requerido', isError: true);
      return;
    }

    setState(() => isSaving = true);
    try {
      final token = ref.read(authProvider).token!;
      final data = {'nombre': _nombreCtrl.text.trim(), 'activo': _activo};

      // Mapear el campo de texto a la columna correcta según la tabla
      if (widget.endpoint == 'unidades-medida') {
        data['abreviatura'] = _descCtrl.text.trim();
      } else {
        data['descripcion'] = _descCtrl.text.trim();
      }

      if (selectedItem == null) {
        await api.create(token, data);
        _showSnack('Creado exitosamente');
      } else {
        await api.update(token, selectedItem!['id'], data);
        _showSnack('Actualizado exitosamente');
      }
      _clearForm();
      _loadData(showLoading: false);
    } catch (e) {
      _showSnack('Error al guardar: $e', isError: true);
    } finally {
      setState(() => isSaving = false);
    }
  }

  Future<void> _delete() async {
    if (selectedItem == null) return;

    bool? confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar'),
        content: const Text('¿Desea eliminar este registro?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => isSaving = true);
    try {
      final token = ref.read(authProvider).token!;
      await api.delete(token, selectedItem!['id']);
      _showSnack('Eliminado exitosamente');
      _clearForm();
      _loadData(showLoading: false);
    } catch (e) {
      _showSnack('Error al eliminar: $e', isError: true);
    } finally {
      setState(() => isSaving = false);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text(widget.titulo),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0, top: 10, bottom: 10),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Nuevo'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: _clearForm,
            ),
          ),
        ],
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Lado Lista
          Expanded(
            flex: 1,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(right: BorderSide(color: Colors.grey.shade300)),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: CustomTextField(
                      label: '',
                      hintText: 'Buscar...',
                      controller: _searchCtrl,
                      onChanged: _onSearch,
                      prefixIcon: Icons.search,
                    ),
                  ),
                  Expanded(
                    child: isLoading
                        ? const Center(child: CustomLoading())
                        : items.isEmpty
                        ? const Center(child: Text('No hay resultados'))
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: items.length,
                            itemBuilder: (ctx, i) {
                              final item = items[i];
                              final isSelected =
                                  selectedItem?['id'] == item['id'];
                              return CardModerno(
                                title: item['nombre'] ?? '',
                                subtitle:
                                    item['descripcion'] ??
                                    item['abreviatura'] ??
                                    '',
                                isActive:
                                    item['activo'] == 1 ||
                                    item['activo'] == true,
                                isSelected: isSelected,
                                onTap: () => _selectItem(item),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
          // Lado Formulario
          Expanded(
            flex: 2,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Card(
                elevation: 0,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        selectedItem == null
                            ? 'Nuevo Registro'
                            : 'Editar Registro',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 24),
                      CustomTextField(label: 'Nombre', controller: _nombreCtrl),
                      const SizedBox(height: 16),
                      CustomTextField(
                        label: 'Descripción',
                        controller: _descCtrl,
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Text(
                            'Estado Activo',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          Switch(
                            value: _activo,
                            onChanged: (val) => setState(() => _activo = val),
                            activeThumbColor: AppColors.primary,
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (selectedItem != null) ...[
                            TextButton.icon(
                              onPressed: isSaving ? null : _delete,
                              icon: const Icon(Icons.delete, color: Colors.red),
                              label: const Text(
                                'Eliminar',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                            const SizedBox(width: 16),
                          ],
                          CustomButton(
                            title: 'Guardar',
                            width: 140,
                            onPressed: isSaving ? () {} : _save,
                            backgroundColor: AppColors.primary,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
