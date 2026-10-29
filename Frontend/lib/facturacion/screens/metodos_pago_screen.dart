import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../palletes/app_colors.dart';
import '../models/metodo_pago.dart';
import '../providers/metodo_pago_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/configuracion_contable_provider.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_confirm_dialog.dart';

class MetodosPagoScreen extends ConsumerStatefulWidget {
  const MetodosPagoScreen({super.key});

  @override
  ConsumerState<MetodosPagoScreen> createState() => _MetodosPagoScreenState();
}

class _MetodosPagoScreenState extends ConsumerState<MetodosPagoScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _filtroTipo = 'todos';
  String _filtroEstado = 'todos';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cargarDatos();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _cargarDatos({bool forceRefresh = true}) {
    ref.read(metodoPagoProvider).fetchTodos(forceRefresh: forceRefresh);
    final token = ref.read(authProvider).token;
    if (token != null) {
      ref.read(configuracionContableProvider.notifier).loadAllData(token);
    }
  }

  void _abrirDialogoMetodo([MetodoPago? metodo]) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _MetodoPagoDialog(metodo: metodo),
    );
  }

  Future<void> _confirmarEliminar(MetodoPago metodo) async {
    final confirmed = await CustomConfirmDialog.show(
      context,
      title: 'Eliminar Método de Pago',
      message: '¿Está seguro de que desea eliminar "${metodo.nombre}"? Esta acción no se puede deshacer.',
      confirmText: 'Eliminar',
      cancelText: 'Cancelar',
      icon: Icons.delete_outline_rounded,
      primaryColor: const Color(0xFFDC2626),
    );

    if (confirmed == true && mounted) {
      try {
        await ref.read(metodoPagoProvider).eliminarMetodo(metodo.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Método "${metodo.nombre}" eliminado correctamente.'),
              backgroundColor: const Color(0xFF0F172A),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al eliminar: $e'),
              backgroundColor: const Color(0xFFDC2626),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  List<MetodoPago> _filtrarMetodos(List<MetodoPago> metodos) {
    final query = _searchCtrl.text.trim().toLowerCase();

    return metodos.where((m) {
      // Filtro de texto
      final matchQuery = query.isEmpty ||
          m.nombre.toLowerCase().contains(query) ||
          m.tipo.toLowerCase().contains(query) ||
          (m.cuentaContable?['nombre'] ?? '').toString().toLowerCase().contains(query) ||
          (m.cuentaContable?['codigo'] ?? '').toString().toLowerCase().contains(query);

      if (!matchQuery) return false;

      // Filtro de tipo
      if (_filtroTipo != 'todos' && m.tipo.toLowerCase() != _filtroTipo) {
        return false;
      }

      // Filtro de estado
      if (_filtroEstado == 'activos' && !m.activo) return false;
      if (_filtroEstado == 'inactivos' && m.activo) return false;

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(metodoPagoProvider);
    final metodos = state.metodos;
    final metodosFiltrados = _filtrarMetodos(metodos);

    final totalCount = metodos.length;
    final activosCount = metodos.where((m) => m.activo).length;
    final conCuentaCount = metodos.where((m) => m.catalogoCuentaId != null || m.cuentaContable != null).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Volver',
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Métodos de Pago',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
                letterSpacing: -0.2,
              ),
            ),
            Text(
              'Configuración de vías de cobro y mapeo contable',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 20),
            tooltip: 'Actualizar lista',
            onPressed: () => _cargarDatos(forceRefresh: true),
            splashRadius: 18,
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16, left: 6),
            child: Center(
              child: SizedBox(
                height: 36,
                child: ElevatedButton.icon(
                  onPressed: () => _abrirDialogoMetodo(),
                  icon: const Icon(Icons.add_rounded, size: 17),
                  label: const Text(
                    'Nuevo Método',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.azulOscuro,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFE2E8F0), height: 1),
        ),
      ),
      body: state.isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: AppColors.azulOscuro,
                strokeWidth: 2.5,
              ),
            )
          : state.error.isNotEmpty
              ? Center(
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    margin: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFCA5A5)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline_rounded, color: Color(0xFFDC2626), size: 36),
                        const SizedBox(height: 10),
                        Text(
                          'Error al cargar métodos de pago',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          state.error,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                        ),
                        const SizedBox(height: 14),
                        ElevatedButton.icon(
                          onPressed: () => _cargarDatos(forceRefresh: true),
                          icon: const Icon(Icons.refresh_rounded, size: 16),
                          label: const Text('Reintentar'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.azulOscuro,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Métricas Principales (KPIs)
                      _buildMetricsRow(totalCount, activosCount, conCuentaCount),

                      const SizedBox(height: 16),

                      // 2. Barra de Filtros y Búsqueda
                      _buildFilterBar(metodos.length),

                      const SizedBox(height: 16),

                      // 3. Grid / Lista de Métodos de Pago
                      if (metodosFiltrados.isEmpty)
                        _buildEmptyState()
                      else
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final width = constraints.maxWidth;
                            final int crossAxisCount = width > 1100 ? 3 : (width > 680 ? 2 : 1);
                            
                            return GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                crossAxisSpacing: 14,
                                mainAxisSpacing: 14,
                                mainAxisExtent: 148,
                              ),
                              itemCount: metodosFiltrados.length,
                              itemBuilder: (context, index) {
                                return _buildMetodoCard(metodosFiltrados[index]);
                              },
                            );
                          },
                        ),

                      const SizedBox(height: 30),
                    ],
                  ),
                ),
    );
  }

  // --- KPI Cards ---
  Widget _buildMetricsRow(int total, int activos, int conCuenta) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 600;

        return Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                title: 'TOTAL MÉTODOS',
                value: total.toString(),
                subtitle: 'Configurados en el sistema',
                icon: Icons.payments_outlined,
                color: AppColors.azulOscuro,
                isCompact: isCompact,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                title: 'MÉTODOS ACTIVOS',
                value: activos.toString(),
                subtitle: 'Disponibles para facturar',
                icon: Icons.check_circle_outline_rounded,
                color: const Color(0xFF059669),
                isCompact: isCompact,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                title: 'CON ENLACE CONTABLE',
                value: '$conCuenta / $total',
                subtitle: 'Mapeados a cuentas contables',
                icon: Icons.account_tree_outlined,
                color: const Color(0xFF2563EB),
                isCompact: isCompact,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isCompact,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF64748B),
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: isCompact ? 16 : 18,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF0F172A),
                    letterSpacing: -0.5,
                  ),
                ),
                if (!isCompact) ...[
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10.5,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Filtros y Búsqueda ---
  Widget _buildFilterBar(int totalTotal) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        alignment: WrapAlignment.spaceBetween,
        children: [
          // Campo de búsqueda
          SizedBox(
            width: 280,
            height: 36,
            child: TextField(
              controller: _searchCtrl,
              onChanged: (_) => setState(() {}),
              style: const TextStyle(fontSize: 12),
              decoration: InputDecoration(
                hintText: 'Buscar método o cuenta...',
                hintStyle: TextStyle(fontSize: 11.5, color: Colors.grey.shade400),
                prefixIcon: const Icon(Icons.search, size: 16, color: Color(0xFF64748B)),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 14),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() {});
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                  borderSide: BorderSide(color: AppColors.azulOscuro, width: 1.5),
                ),
              ),
            ),
          ),

          // Filtros de Tipo y Estado
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              // Filtro Tipo
              _buildFilterChip(
                label: 'Todos',
                isSelected: _filtroTipo == 'todos',
                onSelected: () => setState(() => _filtroTipo = 'todos'),
              ),
              _buildFilterChip(
                label: 'Efectivo',
                icon: Icons.payments_outlined,
                isSelected: _filtroTipo == 'efectivo',
                onSelected: () => setState(() => _filtroTipo = 'efectivo'),
              ),
              _buildFilterChip(
                label: 'Tarjeta',
                icon: Icons.credit_card_outlined,
                isSelected: _filtroTipo == 'tarjeta',
                onSelected: () => setState(() => _filtroTipo = 'tarjeta'),
              ),
              _buildFilterChip(
                label: 'Transferencia',
                icon: Icons.account_balance_outlined,
                isSelected: _filtroTipo == 'transferencia',
                onSelected: () => setState(() => _filtroTipo = 'transferencia'),
              ),

              Container(height: 20, width: 1, color: const Color(0xFFCBD5E1)),

              // Filtro Estado
              _buildFilterChip(
                label: 'Solo Activos',
                isSelected: _filtroEstado == 'activos',
                onSelected: () => setState(() {
                  _filtroEstado = _filtroEstado == 'activos' ? 'todos' : 'activos';
                }),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    IconData? icon,
    required bool isSelected,
    required VoidCallback onSelected,
  }) {
    return InkWell(
      onTap: onSelected,
      borderRadius: BorderRadius.circular(6),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.azulOscuro : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? AppColors.azulOscuro : const Color(0xFFE2E8F0),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 13,
                color: isSelected ? Colors.white : const Color(0xFF475569),
              ),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected ? Colors.white : const Color(0xFF475569),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Card de Método de Pago ---
  Widget _buildMetodoCard(MetodoPago m) {
    Color typeColor;
    IconData typeIcon;
    String typeLabel;

    switch (m.tipo.toLowerCase()) {
      case 'tarjeta':
        typeColor = const Color(0xFF2563EB);
        typeIcon = Icons.credit_card_rounded;
        typeLabel = 'TARJETA';
        break;
      case 'transferencia':
        typeColor = const Color(0xFF7C3AED);
        typeIcon = Icons.account_balance_rounded;
        typeLabel = 'TRANSFERENCIA';
        break;
      case 'efectivo':
      default:
        typeColor = const Color(0xFF059669);
        typeIcon = Icons.payments_rounded;
        typeLabel = 'EFECTIVO';
        break;
    }

    final tieneCuenta = m.cuentaContable != null || m.catalogoCuentaId != null;
    final cuentaCodigo = m.cuentaContable?['codigo'] ?? '';
    final cuentaNombre = m.cuentaContable?['nombre'] ?? '';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: m.activo ? const Color(0xFFE2E8F0) : const Color(0xFFF1F5F9),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: m.activo ? 0.03 : 0.01),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Cabecera de la Card
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: typeColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(typeIcon, color: typeColor, size: 17),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      m.nombre,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: m.activo ? const Color(0xFF0F172A) : const Color(0xFF94A3B8),
                        letterSpacing: -0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 1),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: typeColor.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            typeLabel,
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: typeColor,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: m.activo ? const Color(0xFF10B981) : Colors.grey.shade400,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          m.activo ? 'Activo' : 'Inactivo',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: m.activo ? const Color(0xFF059669) : Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Enlace con Cuenta Contable
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.account_tree_outlined,
                  size: 13,
                  color: tieneCuenta ? const Color(0xFF2563EB) : const Color(0xFFD97706),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    tieneCuenta
                        ? (cuentaCodigo.isNotEmpty ? '$cuentaCodigo · $cuentaNombre' : cuentaNombre)
                        : 'Sin cuenta contable asociada',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: tieneCuenta ? FontWeight.w700 : FontWeight.w500,
                      color: tieneCuenta ? const Color(0xFF1E293B) : const Color(0xFFD97706),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          // Footer de la Card con Switch y Acciones
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Switch de Estado Activo
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Transform.scale(
                    scale: 0.75,
                    child: Switch(
                      value: m.activo,
                      activeThumbColor: AppColors.primary,
                      onChanged: (val) {
                        ref.read(metodoPagoProvider).actualizarMetodo(
                          m.id,
                          {'activo': val},
                        );
                      },
                    ),
                  ),
                  Text(
                    m.activo ? 'Habilitado' : 'Desactivado',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),

              // Botones de Acción
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 16),
                    tooltip: 'Editar método',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                    splashRadius: 14,
                    color: const Color(0xFF475569),
                    onPressed: () => _abrirDialogoMetodo(m),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, size: 16),
                    tooltip: 'Eliminar método',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                    splashRadius: 14,
                    color: const Color(0xFFDC2626),
                    onPressed: () => _confirmarEliminar(m),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(32),
        margin: const EdgeInsets.only(top: 30),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.search_off_rounded, color: Color(0xFF64748B), size: 26),
            ),
            const SizedBox(height: 12),
            const Text(
              'No se encontraron métodos de pago',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 4),
            Text(
              'Pruebe ajustando los filtros de búsqueda o registre un nuevo método.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _abrirDialogoMetodo(),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Crear Método de Pago'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.azulOscuro,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// DIÁLOGO COMPACTO Y ELEGANTE DE MÉTODO DE PAGO
// ==========================================
class _MetodoPagoDialog extends ConsumerStatefulWidget {
  final MetodoPago? metodo;
  const _MetodoPagoDialog({this.metodo});

  @override
  ConsumerState<_MetodoPagoDialog> createState() => _MetodoPagoDialogState();
}

class _MetodoPagoDialogState extends ConsumerState<_MetodoPagoDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nombreCtrl;
  String _tipo = 'efectivo';
  int? _catalogoCuentaId;
  bool _activo = true;
  bool _isSaving = false;

  bool get isEditing => widget.metodo != null;

  @override
  void initState() {
    super.initState();
    _nombreCtrl = TextEditingController(text: widget.metodo?.nombre ?? '');
    _tipo = widget.metodo?.tipo ?? 'efectivo';
    _catalogoCuentaId = widget.metodo?.catalogoCuentaId;
    _activo = widget.metodo?.activo ?? true;
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final data = {
      'nombre': _nombreCtrl.text.trim(),
      'tipo': _tipo,
      'catalogo_cuenta_id': _catalogoCuentaId,
      'activo': _activo,
    };

    try {
      if (widget.metodo == null) {
        await ref.read(metodoPagoProvider).crearMetodo(data);
      } else {
        await ref.read(metodoPagoProvider).actualizarMetodo(widget.metodo!.id, data);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar: $e'),
            backgroundColor: const Color(0xFFDC2626),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cuentas = ref.watch(configuracionContableProvider).catalogoCuentas;
    final cuentasTransaccionales = cuentas.where((c) => c.permiteMovimiento).toList();

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        width: 480,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header del diálogo
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 14, 12),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.azulOscuro.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      isEditing ? Icons.edit_note_rounded : Icons.payments_outlined,
                      size: 17,
                      color: AppColors.azulOscuro,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isEditing ? 'Editar Método de Pago' : 'Nuevo Método de Pago',
                          style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          'Configure el canal de cobro y su cuenta contable asociada',
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded, size: 18),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                    splashRadius: 16,
                    color: Colors.grey.shade500,
                  ),
                ],
              ),
            ),

            const Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0)),

            // Formulario
            Padding(
              padding: const EdgeInsets.all(18),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Nombre del Método
                    CustomTextField(
                      controller: _nombreCtrl,
                      label: 'Nombre del Método *',
                      hintText: 'Ej. Efectivo RD\$, Tarjeta Visa/Master, BHD...',
                      prefixIcon: Icons.badge_outlined,
                      validator: (v) => v!.trim().isEmpty ? 'El nombre es obligatorio' : null,
                    ),

                    const SizedBox(height: 12),

                    // 2. Tipo de Método de Pago (Selector interactivo)
                    Text(
                      'Tipo de Pago',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTypeOption(
                            tipo: 'efectivo',
                            label: 'Efectivo',
                            icon: Icons.payments_rounded,
                            color: const Color(0xFF059669),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildTypeOption(
                            tipo: 'tarjeta',
                            label: 'Tarjeta',
                            icon: Icons.credit_card_rounded,
                            color: const Color(0xFF2563EB),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildTypeOption(
                            tipo: 'transferencia',
                            label: 'Transferencia',
                            icon: Icons.account_balance_rounded,
                            color: const Color(0xFF7C3AED),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // 3. Cuenta Contable Asociada
                    Text(
                      'Cuenta Contable de Enlace (Opcional)',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    DropdownButtonFormField<int?>(
                      initialValue: _catalogoCuentaId,
                      isExpanded: true,
                      style: const TextStyle(fontSize: 11.5, color: Color(0xFF0F172A), fontWeight: FontWeight.w600),
                      items: [
                        const DropdownMenuItem<int?>(
                          value: null,
                          child: Text(
                            '-- Ninguna cuenta contable asignada --',
                            style: TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.normal),
                          ),
                        ),
                        ...cuentasTransaccionales.map(
                          (c) => DropdownMenuItem<int?>(
                            value: c.id,
                            child: Text(
                              '${c.codigo} · ${c.nombre}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                      onChanged: (v) => setState(() => _catalogoCuentaId = v),
                      decoration: InputDecoration(
                        prefixIcon: Icon(
                          Icons.account_tree_outlined,
                          size: 15,
                          color: AppColors.azulOscuro.withValues(alpha: 0.7),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        focusedBorder: const OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(8)),
                          borderSide: BorderSide(color: AppColors.azulOscuro, width: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Esta cuenta recibirá el débito automático al registrar cobros con este método.',
                      style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                    ),

                    const SizedBox(height: 12),

                    // 4. Switch Estado Activo
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Método Activo',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 11,
                                  color: Color(0xFF334155),
                                ),
                              ),
                              Text(
                                'Disponible para cobros en caja y facturación',
                                style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                              ),
                            ],
                          ),
                          const Spacer(),
                          Transform.scale(
                            scale: 0.75,
                            child: Switch(
                              value: _activo,
                              activeThumbColor: AppColors.primary,
                              onChanged: (val) => setState(() => _activo = val),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Footer con Botones
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAFC),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(14)),
                border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF475569),
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Cancelar', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _isSaving ? null : _guardar,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Icon(Icons.check_rounded, size: 15),
                    label: Text(
                      isEditing ? 'Actualizar Método' : 'Guardar Método',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.azulOscuro,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeOption({
    required String tipo,
    required String label,
    required IconData icon,
    required Color color,
  }) {
    final isSelected = _tipo == tipo;

    return InkWell(
      onTap: () => setState(() => _tipo = tipo),
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.08) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? color : const Color(0xFFE2E8F0),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: isSelected ? color : const Color(0xFF64748B)),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? color : const Color(0xFF475569),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
