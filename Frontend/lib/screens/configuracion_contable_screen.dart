import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../model/catalogo_cuenta_model.dart';
import '../modulo_contabilidad/widgets/config_contable_widgets.dart';
import '../modulo_contabilidad/widgets/contabilidad_shared_widgets.dart';
import '../palletes/app_colors.dart';
import '../providers/auth_provider.dart';
import '../providers/configuracion_contable_provider.dart';
import '../providers/configuracion_contable_state.dart';
import '../utils/helpers.dart';
import '../widgets/custom_empty_state.dart';
import '../widgets/custom_text_field.dart';

class ConfiguracionContableScreen extends ConsumerStatefulWidget {
  const ConfiguracionContableScreen({super.key});

  @override
  ConsumerState<ConfiguracionContableScreen> createState() =>
      _ConfiguracionContableScreenState();
}

class _ConfiguracionContableScreenState
    extends ConsumerState<ConfiguracionContableScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final TextEditingController _searchCtrl = TextEditingController();
  final Map<int, int?> _localChanges = {};
  String _search = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _recargar());
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _recargar() {
    final token = ref.read(authProvider).token;
    if (token != null) {
      ref.read(configuracionContableProvider.notifier).loadAllData(token);
    }
  }

  void _abrirSelector({
    required List<CatalogoCuentaModel> accounts,
    required int configId,
    required int? currentAccountId,
    required String configName,
  }) {
    showDialog(
      context: context,
      builder: (_) => ConfigCuentaSelectorDialog(
        accounts: accounts,
        currentAccountId: currentAccountId,
        configName: configName,
        onSelected: (newId) {
          setState(() => _localChanges[configId] = newId);
        },
      ),
    );
  }

  void _discardChanges() {
    setState(() => _localChanges.clear());
    showToast(context, 'Cambios locales descartados', bgColor: Colors.blueGrey);
  }

  Future<void> _saveChanges() async {
    if (_localChanges.isEmpty) return;
    final token = ref.read(authProvider).token;
    if (token == null) return;

    final payload = _localChanges.entries
        .map((e) => {'id': e.key, 'cuenta_id': e.value})
        .toList();

    final ok = await ref
        .read(configuracionContableProvider.notifier)
        .saveBulkConfigurations(token, payload);

    if (!mounted) return;
    if (ok) {
      setState(() => _localChanges.clear());
      showToast(
        context,
        'Configuraciones contables actualizadas correctamente',
        bgColor: Colors.teal.shade700,
      );
    } else {
      final err = ref.read(configuracionContableProvider).errorMessage;
      showToast(
        context,
        'Error al guardar: ${err ?? "Error desconocido"}',
        bgColor: AppColors.danger,
      );
    }
  }

  Widget _buildGroupTable(ConfiguracionContableState state, String group) {
    final q = _search.trim().toLowerCase();
    final items = state.configuraciones.where((c) {
      if (c.grupo != group) return false;
      if (q.isEmpty) return true;
      return c.nombre.toLowerCase().contains(q) ||
          c.clave.toLowerCase().contains(q);
    }).toList();

    if (items.isEmpty) {
      return const CustomEmptyState(
        title: 'No hay reglas contables en este grupo',
        icon: Icons.rule_folder_outlined,
      );
    }

    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (_, i) {
        final cfg = items[i];
        final isMod = _localChanges.containsKey(cfg.id);
        final accId = isMod ? _localChanges[cfg.id] : cfg.cuentaId;
        final selected = accId != null
            ? state.catalogoCuentas.where((a) => a.id == accId).firstOrNull
            : null;
        return ConfigContableRuleRow(
          config: cfg,
          selectedAccount: selected,
          isModified: isMod,
          onSelectTap: () => _abrirSelector(
            accounts: state.catalogoCuentas,
            configId: cfg.id,
            currentAccountId: accId,
            configName: cfg.nombre,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(configuracionContableProvider);
    final total = state.configuraciones.length;
    final asignadas = state.configuraciones.where((c) {
      final id = _localChanges.containsKey(c.id)
          ? _localChanges[c.id]
          : c.cuentaId;
      return id != null;
    }).length;
    final sinAsignar = total - asignadas;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        elevation: 0.5,
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: AppColors.azulOscuro),
        title: const Text(
          'Configuración Contable Automática',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.azulOscuro,
          ),
        ),
        actions: [
          if (_localChanges.isNotEmpty) ...[
            OutlinedButton(
              onPressed: state.isSaving ? null : _discardChanges,
              child: const Text(
                'Descartar',
                style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: state.isSaving ? null : _saveChanges,
              icon: state.isSaving
                  ? const SizedBox(
                      width: 13,
                      height: 13,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.save_rounded, size: 15),
              label: Text(
                state.isSaving
                    ? 'Guardando...'
                    : 'Guardar (${_localChanges.length})',
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
              ),
            ),
            const SizedBox(width: 6),
          ],
          IconButton(
            visualDensity: VisualDensity.compact,
            tooltip: 'Actualizar configuraciones',
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
                  child: ContabilidadKpiChip(
                    label: 'Total Reglas',
                    value: '$total',
                    icon: Icons.settings_suggest_outlined,
                    color: AppColors.azulOscuro,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ContabilidadKpiChip(
                    label: 'Cuentas Asignadas',
                    value: '$asignadas',
                    icon: Icons.check_circle_outline_rounded,
                    color: Colors.green.shade700,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ContabilidadKpiChip(
                    label: 'Sin Asignar',
                    value: '$sinAsignar',
                    icon: Icons.warning_amber_rounded,
                    color: sinAsignar > 0
                        ? Colors.orange.shade800
                        : Colors.grey.shade600,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ContabilidadKpiChip(
                    label: 'Cambios Pendientes',
                    value: '${_localChanges.length}',
                    icon: Icons.edit_note_rounded,
                    color: _localChanges.isNotEmpty
                        ? AppColors.primaryDark
                        : Colors.indigo.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 5,
                    child: SizedBox(
                      height: 36,
                      child: TabBar(
                        controller: _tabController,
                        labelColor: AppColors.primaryDark,
                        unselectedLabelColor: Colors.grey.shade600,
                        indicatorColor: AppColors.primary,
                        indicatorWeight: 2.5,
                        dividerColor: Colors.transparent,
                        labelStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                        unselectedLabelStyle: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                        ),
                        tabs: const [
                          Tab(text: 'Ventas y Facturación'),
                          Tab(text: 'Compras e Inventarios'),
                          Tab(text: 'Nómina y Salarios'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 3,
                    child: CustomTextField(
                      controller: _searchCtrl,
                      label: '',
                      hintText: 'Filtrar regla o clave...',
                      prefixIcon: Icons.search_rounded,
                      onChanged: (v) => setState(() => _search = v),
                    ),
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
                          SizedBox(
                            width: 96,
                            child: ContabilidadTableHeaderText('Naturaleza'),
                          ),
                          Expanded(
                            flex: 5,
                            child: ContabilidadTableHeaderText(
                              'Operación / Regla Contable Automática',
                            ),
                          ),
                          Expanded(
                            flex: 4,
                            child: ContabilidadTableHeaderText(
                              'Cuenta Transaccional Asignada',
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: state.isLoading && state.configuraciones.isEmpty
                          ? const Center(child: CircularProgressIndicator())
                          : TabBarView(
                              controller: _tabController,
                              children: [
                                _buildGroupTable(state, 'Ventas'),
                                _buildGroupTable(state, 'Compras'),
                                _buildGroupTable(state, 'Nomina'),
                              ],
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
