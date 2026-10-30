import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../model/catalogo_cuenta_model.dart';
import '../../palletes/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/configuracion_contable_provider.dart';
import '../../widgets/custom_confirm_dialog.dart';
import '../../widgets/custom_empty_state.dart';
import '../../widgets/custom_filter_dropdown.dart';
import '../../widgets/custom_text_field.dart';
import '../widgets/catalogo_cuenta_dialog.dart';
import '../widgets/catalogo_cuenta_row.dart';

class CatalogoCuentasScreen extends ConsumerStatefulWidget {
  const CatalogoCuentasScreen({super.key});

  @override
  ConsumerState<CatalogoCuentasScreen> createState() =>
      _CatalogoCuentasScreenState();
}

class _CatalogoCuentasScreenState extends ConsumerState<CatalogoCuentasScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  final Set<int> _collapsedIds = {};
  String _search = '';
  String _filtroTipo = '';
  String _filtroUso = ''; // '', 'transaccional', 'grupo'

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _recargar());
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _recargar() {
    final token = ref.read(authProvider).token;
    if (token != null) {
      ref.read(configuracionContableProvider.notifier).loadAllData(token);
    }
  }

  void _abrirDialogo([
    CatalogoCuentaModel? cuenta,
    CatalogoCuentaModel? padre,
  ]) {
    showDialog(
      context: context,
      builder: (_) =>
          CatalogoCuentaDialog(cuenta: cuenta, cuentaPadreDefault: padre),
    );
  }

  Future<void> _eliminarCuenta(CatalogoCuentaModel cuenta) async {
    final confirmar = await CustomConfirmDialog.show(
      context,
      title: 'Eliminar Cuenta Contable',
      message:
          '¿Deseas eliminar la cuenta "${cuenta.codigo} - ${cuenta.nombre}"?',
      confirmText: 'Eliminar',
      icon: Icons.delete_outline_rounded,
      primaryColor: Colors.red.shade700,
    );

    if (confirmar != true) return;
    final token = ref.read(authProvider).token;
    if (token == null) return;

    try {
      await ref
          .read(configuracionContableProvider.notifier)
          .eliminarCuenta(token, cuenta.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Cuenta eliminada correctamente.',
              style: TextStyle(fontSize: 12),
            ),
            backgroundColor: Colors.teal.shade700,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e', style: const TextStyle(fontSize: 12)),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  int _compareCodigos(String a, String b) {
    final pa = a.split('.');
    final pb = b.split('.');
    final len = pa.length < pb.length ? pa.length : pb.length;
    for (int i = 0; i < len; i++) {
      final na = int.tryParse(pa[i]);
      final nb = int.tryParse(pb[i]);
      final cmp = (na != null && nb != null)
          ? na.compareTo(nb)
          : pa[i].compareTo(pb[i]);
      if (cmp != 0) return cmp;
    }
    return pa.length.compareTo(pb.length);
  }

  void _toggleAll(List<CatalogoCuentaModel> todas) {
    final padres = todas
        .where((p) => todas.any((h) => h.padreId == p.id))
        .map((p) => p.id)
        .toSet();
    setState(() {
      if (_collapsedIds.length >= padres.length && padres.isNotEmpty) {
        _collapsedIds.clear();
      } else {
        _collapsedIds
          ..clear()
          ..addAll(padres);
      }
    });
  }

  List<_NodeEntry> _buildVisibleEntries(List<CatalogoCuentaModel> todas) {
    final subset = _filtroTipo.isEmpty
        ? todas
        : todas
              .where((c) => c.tipo.toLowerCase() == _filtroTipo.toLowerCase())
              .toList();

    final isFlatSearch = _search.trim().isNotEmpty || _filtroUso.isNotEmpty;
    if (isFlatSearch) {
      final q = _search.trim().toLowerCase();
      final matches = subset.where((c) {
        if (_filtroUso == 'transaccional' && !c.permiteMovimiento) return false;
        if (_filtroUso == 'grupo' && c.permiteMovimiento) return false;
        if (q.isNotEmpty &&
            !c.codigo.toLowerCase().contains(q) &&
            !c.nombre.toLowerCase().contains(q)) {
          return false;
        }
        return true;
      }).toList()..sort((a, b) => _compareCodigos(a.codigo, b.codigo));

      return matches.map((c) {
        final hijosCount = todas.where((h) => h.padreId == c.id).length;
        final d = _filtroUso.isNotEmpty ? 0 : (c.nivel - 1).clamp(0, 4);
        return _NodeEntry(c, d, hijosCount);
      }).toList();
    }

    final result = <_NodeEntry>[];
    void walk(int? padreId, int depth) {
      final hijos = subset.where((c) => c.padreId == padreId).toList()
        ..sort((a, b) => _compareCodigos(a.codigo, b.codigo));
      for (final h in hijos) {
        final directChildren = subset.where((c) => c.padreId == h.id).length;
        result.add(_NodeEntry(h, depth, directChildren));
        if (directChildren > 0 && !_collapsedIds.contains(h.id)) {
          walk(h.id, depth + 1);
        }
      }
    }

    walk(null, 0);
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(configuracionContableProvider);
    final todas = state.catalogoCuentasCompleto;
    final entries = _buildVisibleEntries(todas);

    final transaccionales = todas.where((c) => c.permiteMovimiento).length;
    final grupos = todas.length - transaccionales;
    final raices = todas.where((c) => c.padreId == null).length;
    final padresCount = todas
        .where((p) => todas.any((h) => h.padreId == p.id))
        .length;
    final todoColapsado =
        padresCount > 0 && _collapsedIds.length >= padresCount;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        elevation: 0.5,
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: AppColors.azulOscuro),
        title: const Text(
          'Catálogo de Cuentas',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.azulOscuro,
          ),
        ),
        actions: [
          OutlinedButton.icon(
            onPressed: todas.isEmpty ? null : () => _toggleAll(todas),
            icon: Icon(
              todoColapsado
                  ? Icons.unfold_more_rounded
                  : Icons.unfold_less_rounded,
              size: 16,
            ),
            label: Text(
              todoColapsado ? 'Expandir Todo' : 'Colapsar Grupos',
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: () => _abrirDialogo(),
            icon: const Icon(Icons.add_rounded, size: 16),
            label: const Text(
              'Nueva Cuenta Raíz',
              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.azulOscuro,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
          ),
          const SizedBox(width: 6),
          IconButton(
            visualDensity: VisualDensity.compact,
            tooltip: 'Actualizar catálogo',
            icon: const Icon(Icons.refresh_rounded, size: 19),
            onPressed: _recargar,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _MiniStat(
                    label: 'Total Cuentas',
                    val: todas.length.toString(),
                    icon: Icons.account_tree_outlined,
                    color: AppColors.azulOscuro,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _MiniStat(
                    label: 'Transaccionales',
                    val: transaccionales.toString(),
                    icon: Icons.check_circle_outline_rounded,
                    color: Colors.green.shade700,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _MiniStat(
                    label: 'Grupos / Padres',
                    val: grupos.toString(),
                    icon: Icons.folder_open_rounded,
                    color: AppColors.primaryDark,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _MiniStat(
                    label: 'Rubros Raíz',
                    val: raices.toString(),
                    icon: Icons.layers_outlined,
                    color: Colors.indigo.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: _searchCtrl,
                      label: '',
                      hintText:
                          'Buscar por código contable (1.1.01) o nombre...',
                      prefixIcon: Icons.search_rounded,
                      onChanged: (v) => setState(() => _search = v),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CustomFilterDropdown<String>(
                    height: 36,
                    value: _filtroTipo,
                    items: const [
                      DropdownMenuItem(value: '', child: Text('Tipo: Todos')),
                      DropdownMenuItem(value: 'Activo', child: Text('Activo')),
                      DropdownMenuItem(value: 'Pasivo', child: Text('Pasivo')),
                      DropdownMenuItem(
                        value: 'Capital',
                        child: Text('Capital'),
                      ),
                      DropdownMenuItem(
                        value: 'Ingresos',
                        child: Text('Ingresos'),
                      ),
                      DropdownMenuItem(value: 'Costos', child: Text('Costos')),
                      DropdownMenuItem(value: 'Gastos', child: Text('Gastos')),
                    ],
                    onChanged: (v) => setState(() => _filtroTipo = v ?? ''),
                  ),
                  const SizedBox(width: 8),
                  CustomFilterDropdown<String>(
                    height: 36,
                    value: _filtroUso,
                    items: const [
                      DropdownMenuItem(value: '', child: Text('Uso: Todas')),
                      DropdownMenuItem(
                        value: 'transaccional',
                        child: Text('Solo Transaccionales'),
                      ),
                      DropdownMenuItem(
                        value: 'grupo',
                        child: Text('Solo Grupos'),
                      ),
                    ],
                    onChanged: (v) => setState(() => _filtroUso = v ?? ''),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(10),
                        ),
                      ),
                      child: const Row(
                        children: [
                          Expanded(
                            flex: 6,
                            child: _ColHdr('Código / Estructura Contable'),
                          ),
                          SizedBox(width: 88, child: _ColHdr('Tipo')),
                          SizedBox(
                            width: 62,
                            child: Align(
                              alignment: Alignment.center,
                              child: _ColHdr('Nivel'),
                            ),
                          ),
                          SizedBox(
                            width: 112,
                            child: Align(
                              alignment: Alignment.center,
                              child: _ColHdr('Naturaleza'),
                            ),
                          ),
                          SizedBox(
                            width: 96,
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: _ColHdr('Acciones'),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: state.isLoading && todas.isEmpty
                          ? const Center(child: CircularProgressIndicator())
                          : entries.isEmpty
                          ? const CustomEmptyState(
                              title: 'No se encontraron cuentas contables',
                              icon: Icons.account_tree_outlined,
                            )
                          : ListView.builder(
                              itemCount: entries.length,
                              itemBuilder: (_, i) {
                                final e = entries[i];
                                final c = e.cuenta;
                                final tieneHijos = todas.any(
                                  (h) => h.padreId == c.id,
                                );
                                return CatalogoCuentaRow(
                                  cuenta: c,
                                  depth: e.depth,
                                  totalHijosDirectos: e.directChildren,
                                  isExpanded: !_collapsedIds.contains(c.id),
                                  onToggleExpand: () {
                                    setState(() {
                                      if (!_collapsedIds.remove(c.id)) {
                                        _collapsedIds.add(c.id);
                                      }
                                    });
                                  },
                                  onAddChild: () => _abrirDialogo(null, c),
                                  onEdit: () => _abrirDialogo(c, null),
                                  onDelete: (!tieneHijos && c.nivel > 1)
                                      ? () => _eliminarCuenta(c)
                                      : null,
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NodeEntry {
  final CatalogoCuentaModel cuenta;
  final int depth;
  final int directChildren;
  const _NodeEntry(this.cuenta, this.depth, this.directChildren);
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String val;
  final IconData icon;
  final Color color;

  const _MiniStat({
    required this.label,
    required this.val,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, size: 17, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  val,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ColHdr extends StatelessWidget {
  final String text;
  const _ColHdr(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 10.5,
        fontWeight: FontWeight.w800,
        color: Colors.grey.shade700,
      ),
    );
  }
}
