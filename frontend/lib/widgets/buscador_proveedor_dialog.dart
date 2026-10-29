import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../palletes/app_colors.dart';
import '../utils/get_initials.dart';
import '../modulo_compras/models/proveedor.dart';
import '../modulo_compras/providers/proveedores_provider.dart';
import '../modulo_compras/screens/widgets/add_proveedor_dialog.dart';

/// Diálogo unificado y compacto para seleccionar o crear un Proveedor.
/// Cumple con las guías de flutter-clean-reusable-ui y flutter-small-widgets.
class BuscadorProveedorDialog extends ConsumerStatefulWidget {
  final List<Proveedor>? proveedores;
  final int? selectedId;
  final String title;

  const BuscadorProveedorDialog({
    super.key,
    this.proveedores,
    this.selectedId,
    this.title = 'Seleccionar Proveedor',
  });

  /// Método estático reutilizable para abrir el diálogo de forma limpia desde cualquier pantalla:
  /// ```dart
  /// final proveedor = await BuscadorProveedorDialog.show(context, selectedId: ...);
  /// ```
  static Future<Proveedor?> show(
    BuildContext context, {
    List<Proveedor>? proveedores,
    int? selectedId,
    String title = 'Seleccionar Proveedor',
  }) {
    return showDialog<Proveedor>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => BuscadorProveedorDialog(
        proveedores: proveedores,
        selectedId: selectedId,
        title: title,
      ),
    );
  }

  @override
  ConsumerState<BuscadorProveedorDialog> createState() =>
      _BuscadorProveedorDialogState();
}

class _BuscadorProveedorDialogState
    extends ConsumerState<BuscadorProveedorDialog> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    // Si no se pasaron proveedores explícitos, asegurar carga desde el provider
    if (widget.proveedores == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(proveedoresProvider.notifier).loadProveedores();
      });
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<Proveedor> _getFiltered(List<Proveedor> all) {
    if (_query.trim().isEmpty) return all;
    final q = _query.trim().toLowerCase();
    return all.where((p) {
      final nameMatches = p.nombre.toLowerCase().contains(q);
      final rncMatches = (p.rnc ?? '').toLowerCase().contains(q);
      final telMatches = (p.telefono ?? '').toLowerCase().contains(q);
      final emailMatches = (p.email ?? '').toLowerCase().contains(q);
      return nameMatches || rncMatches || telMatches || emailMatches;
    }).toList();
  }

  Future<void> _abrirNuevoProveedor(List<Proveedor> currentList) async {
    final oldIds = currentList.map((p) => p.id).toSet();
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => const AddProveedorDialog(),
    );

    if (result == true && mounted) {
      await ref.read(proveedoresProvider.notifier).loadProveedores();
      final updatedList = ref.read(proveedoresProvider).proveedores;
      final newEntries =
          updatedList.where((p) => !oldIds.contains(p.id)).toList();
      if (newEntries.isNotEmpty && mounted) {
        Navigator.pop(context, newEntries.first);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(proveedoresProvider);
    final allProveedores = widget.proveedores ?? state.proveedores;
    final filtrados = _getFiltered(allProveedores);
    final isLoading = state.isLoading && allProveedores.isEmpty;

    final media = MediaQuery.of(context).size;
    final dialogWidth = min(media.width * 0.92, 440.0);
    final dialogHeight = min(media.height * 0.82, 520.0);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      clipBehavior: Clip.antiAlias,
      backgroundColor: Colors.white,
      child: SizedBox(
        width: dialogWidth,
        height: dialogHeight,
        child: Column(
          children: [
            // --- HEADER COMPACTO ---
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 10, 10),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.storefront_outlined,
                      color: AppColors.primary,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.secondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${allProveedores.length} proveedores registrados',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Botón "+ Nuevo"
                  ElevatedButton.icon(
                    onPressed: () => _abrirNuevoProveedor(allProveedores),
                    icon: const Icon(Icons.add, size: 14),
                    label: const Text('Nuevo'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      textStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  // Botón cerrar "X"
                  IconButton(
                    icon: Icon(
                      Icons.close,
                      size: 18,
                      color: Colors.grey.shade600,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                    splashRadius: 18,
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // --- BARRA DE BÚSQUEDA COMPACTA ---
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
              child: TextField(
                controller: _searchCtrl,
                autofocus: true,
                style: const TextStyle(fontSize: 12.5),
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 9,
                  ),
                  hintText: 'Buscar por nombre, RNC o teléfono...',
                  hintStyle: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade400,
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    size: 18,
                    color: Colors.grey.shade500,
                  ),
                  prefixIconConstraints: const BoxConstraints(
                    minWidth: 34,
                    minHeight: 34,
                  ),
                  suffixIcon: _query.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 16),
                          splashRadius: 14,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 28,
                            minHeight: 28,
                          ),
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() => _query = '');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                      color: AppColors.primary,
                      width: 1.5,
                    ),
                  ),
                ),
                onChanged: (val) => setState(() => _query = val),
              ),
            ),

            // --- CONTENIDO / LISTA ---
            Expanded(
              child: isLoading
                  ? const Center(
                      child: SizedBox(
                        width: 26,
                        height: 26,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: AppColors.primary,
                        ),
                      ),
                    )
                  : filtrados.isEmpty
                  ? _buildEmptyState(allProveedores)
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      itemCount: filtrados.length,
                      separatorBuilder: (_, index) => const SizedBox(height: 6),
                      itemBuilder: (context, index) {
                        final proveedor = filtrados[index];
                        final isSelected =
                            widget.selectedId != null &&
                            proveedor.id == widget.selectedId;

                        return _buildProveedorTile(
                          proveedor: proveedor,
                          isSelected: isSelected,
                        );
                      },
                    ),
            ),

            // --- FOOTER COMPACTO ---
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${filtrados.length} encontrados',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      foregroundColor: Colors.grey.shade700,
                      textStyle: const TextStyle(fontSize: 12),
                    ),
                    child: const Text('Cerrar'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProveedorTile({
    required Proveedor proveedor,
    required bool isSelected,
  }) {
    final initials = InitialsHelper.getInitials(
      proveedor.nombre,
      defaultChar: 'P',
    );

    return InkWell(
      onTap: () => Navigator.pop(context, proveedor),
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.08)
              : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey.shade200,
            width: isSelected ? 1.5 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            // Avatar con iniciales
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary
                    : AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              alignment: Alignment.center,
              child: Text(
                initials,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : AppColors.primary,
                ),
              ),
            ),
            const SizedBox(width: 10),

            // Información principal
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          proveedor.nombre,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? AppColors.primaryDark
                                : AppColors.secondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (proveedor.esInformal) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade100,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Informal',
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w600,
                              color: Colors.amber.shade900,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      if (proveedor.rnc != null &&
                          proveedor.rnc!.trim().isNotEmpty) ...[
                        Icon(
                          Icons.badge_outlined,
                          size: 12,
                          color: Colors.grey.shade500,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          'RNC: ${proveedor.rnc}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                      if (proveedor.telefono != null &&
                          proveedor.telefono!.trim().isNotEmpty) ...[
                        if (proveedor.rnc != null &&
                            proveedor.rnc!.trim().isNotEmpty)
                          Text(
                            '  •  ',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey.shade400,
                            ),
                          ),
                        Icon(
                          Icons.phone_outlined,
                          size: 12,
                          color: Colors.grey.shade500,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          proveedor.telefono!,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 6),

            // Icono de estado (seleccionado o chevron)
            if (isSelected)
              const Icon(
                Icons.check_circle_rounded,
                color: AppColors.primary,
                size: 18,
              )
            else
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.grey.shade400,
                size: 16,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(List<Proveedor> allProveedores) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _query.isNotEmpty
                  ? Icons.person_search_outlined
                  : Icons.store_mall_directory_outlined,
              size: 40,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 8),
            Text(
              _query.isNotEmpty
                  ? 'Sin coincidencias para "$_query"'
                  : 'No hay proveedores registrados',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _query.isNotEmpty
                  ? 'Verifica la búsqueda o registra el proveedor.'
                  : 'Comienza agregando un proveedor al sistema.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => _abrirNuevoProveedor(allProveedores),
              icon: const Icon(Icons.add, size: 14),
              label: const Text('Registrar Proveedor'),
              style: OutlinedButton.styleFrom(
                visualDensity: VisualDensity.compact,
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                textStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
