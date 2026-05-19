import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sistema_restaurante/model/catalogo_cuenta_model.dart';
import 'package:sistema_restaurante/model/configuracion_contable_model.dart';
import 'package:sistema_restaurante/providers/auth_provider.dart';
import 'package:sistema_restaurante/providers/configuracion_contable_provider.dart';
import 'package:sistema_restaurante/palletes/app_colors.dart';
import 'package:sistema_restaurante/utils/helpers.dart';

import '../providers/configuracion_contable_state.dart';

class ConfiguracionContableScreen extends ConsumerStatefulWidget {
  const ConfiguracionContableScreen({super.key});

  @override
  ConsumerState<ConfiguracionContableScreen> createState() =>
      _ConfiguracionContableScreenState();
}

class _ConfiguracionContableScreenState
    extends ConsumerState<ConfiguracionContableScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Map<int, int?> _localChanges =
      {}; // Maps configId -> accountId (can be null)

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    Future.microtask(() {
      final token = ref.read(authProvider).token;
      if (token != null) {
        ref.read(configuracionContableProvider.notifier).loadAllData(token);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showAccountSearchSelector({
    required List<CatalogoCuentaModel> accounts,
    required int configId,
    required int? currentAccountId,
    required String configName,
  }) {
    showDialog(
      context: context,
      builder: (context) {
        String searchQuery = '';
        return StatefulBuilder(
          builder: (context, setStateBuilder) {
            // Filter accounts
            final filteredAccounts = accounts.where((acc) {
              final query = searchQuery.toLowerCase();
              return acc.codigo.contains(query) ||
                  acc.nombre.toLowerCase().contains(query);
            }).toList();

            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              elevation: 8,
              child: Container(
                width: 500,
                constraints: const BoxConstraints(maxHeight: 600),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Asignar Cuenta Contable',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: AppColors.azulOscuro,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      configName,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      onChanged: (val) {
                        setStateBuilder(() {
                          searchQuery = val;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Buscar por código o nombre...',
                        prefixIcon: const Icon(
                          Icons.search,
                          color: Colors.grey,
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: filteredAccounts.isEmpty
                          ? Center(
                              child: Text(
                                'No se encontraron cuentas',
                                style: TextStyle(color: Colors.grey.shade400),
                              ),
                            )
                          : ListView.builder(
                              itemCount: filteredAccounts.length,
                              itemBuilder: (context, index) {
                                final acc = filteredAccounts[index];
                                final isSelected = currentAccountId == acc.id;

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppColors.primary.withValues(
                                            alpha: 0.08,
                                          )
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSelected
                                          ? AppColors.primary
                                          : Colors.grey.shade200,
                                      width: isSelected ? 1.5 : 1,
                                    ),
                                  ),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 4,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    leading: CircleAvatar(
                                      backgroundColor: isSelected
                                          ? AppColors.primary
                                          : Colors.grey.shade100,
                                      radius: 20,
                                      child: Text(
                                        acc.codigo.split('.').last,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: isSelected
                                              ? Colors.white
                                              : AppColors.azulOscuro,
                                        ),
                                      ),
                                    ),
                                    title: Text(
                                      acc.nombre,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.azulOscuro,
                                      ),
                                    ),
                                    subtitle: Text(
                                      'Código: ${acc.codigo} • ${acc.tipo}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade500,
                                      ),
                                    ),
                                    trailing: isSelected
                                        ? const Icon(
                                            Icons.check_circle,
                                            color: AppColors.primary,
                                          )
                                        : const Icon(
                                            Icons.arrow_forward_ios_rounded,
                                            size: 14,
                                            color: Colors.grey,
                                          ),
                                    onTap: () {
                                      setState(() {
                                        _localChanges[configId] = acc.id;
                                      });
                                      Navigator.pop(context);
                                    },
                                  ),
                                );
                              },
                            ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _localChanges[configId] =
                                  null; // Unassign / clear
                            });
                            Navigator.pop(context);
                          },
                          child: const Text(
                            'Quitar Asignación',
                            style: TextStyle(color: AppColors.danger),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.azulOscuro,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Cerrar'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _discardChanges() {
    setState(() {
      _localChanges.clear();
    });
    showToast(context, 'Cambios locales descartados', bgColor: Colors.blueGrey);
  }

  void _saveChanges() async {
    if (_localChanges.isEmpty) return;

    final token = ref.read(authProvider).token;
    if (token == null) return;

    // Build lists of payloads
    final configsPayload = _localChanges.entries.map((entry) {
      return {'id': entry.key, 'cuenta_id': entry.value};
    }).toList();

    final notifier = ref.read(configuracionContableProvider.notifier);
    final success = await notifier.saveBulkConfigurations(
      token,
      configsPayload,
    );

    if (success && mounted) {
      setState(() {
        _localChanges.clear();
      });
      showToast(
        context,
        'Configuraciones contables actualizadas correctamente',
        bgColor: AppColors.success,
      );
    } else if (mounted) {
      final errorMsg = ref.read(configuracionContableProvider).errorMessage;
      showToast(
        context,
        'Error al guardar: ${errorMsg ?? "Error desconocido"}',
        bgColor: AppColors.danger,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(configuracionContableProvider);
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 900;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Configuración Contable Automática',
          style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white),
        ),
        backgroundColor: AppColors.azulOscuro,
        centerTitle: false,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // 🚀 HEADER BANNER
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            decoration: const BoxDecoration(gradient: AppColors.darkGradient),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FadeInDown(
                  duration: const Duration(milliseconds: 300),
                  child: const Text(
                    'Motor de Operaciones Contables Automáticas',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                FadeInDown(
                  duration: const Duration(milliseconds: 300),
                  delay: const Duration(milliseconds: 100),
                  child: Text(
                    'Asigne las cuentas contables de detalle para automatizar los asientos de ventas, compras y nómina del sistema sin escribir código duro.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade400,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 📊 TAB SEGMENTS CONTROL
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: AppColors.primary,
              unselectedLabelColor: Colors.grey,
              indicatorColor: AppColors.primary,
              indicatorWeight: 3,
              tabs: const [
                Tab(
                  icon: Icon(Icons.shopping_cart_outlined, size: 20),
                  text: 'Ventas y Facturación',
                ),
                Tab(
                  icon: Icon(Icons.inventory_2_outlined, size: 20),
                  text: 'Compras e Inventarios',
                ),
                Tab(
                  icon: Icon(Icons.account_balance_outlined, size: 20),
                  text: 'Nómina y Salarios',
                ),
              ],
            ),
          ),

          // 💼 MAIN BODY
          Expanded(
            child: state.isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildConfigList(state, 'Ventas', isDesktop),
                      _buildConfigList(state, 'Compras', isDesktop),
                      _buildConfigList(state, 'Nomina', isDesktop),
                    ],
                  ),
          ),

          // 💾 ACCIONES FLOTANTES / BOTTOM BAR
          if (_localChanges.isNotEmpty)
            FadeInUp(
              duration: const Duration(milliseconds: 250),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 20,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.edit_note,
                                color: AppColors.primary,
                                size: 18,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${_localChanges.length} configuraciones modificadas',
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        TextButton(
                          onPressed: _discardChanges,
                          child: Text(
                            'Descartar',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton.icon(
                          onPressed: state.isSaving ? null : _saveChanges,
                          icon: state.isSaving
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.save_rounded, size: 18),
                          label: Text(
                            state.isSaving ? 'Guardando...' : 'Guardar Cambios',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildConfigList(
    ConfiguracionContableState state,
    String group,
    bool isDesktop,
  ) {
    final filteredConfigs = state.configuraciones
        .where((c) => c.grupo == group)
        .toList();

    if (filteredConfigs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.layers_clear_outlined,
              size: 64,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              'No hay configuraciones disponibles para este grupo.',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: filteredConfigs.length,
      itemBuilder: (context, index) {
        final config = filteredConfigs[index];
        return SlideInLeft(
          duration: const Duration(milliseconds: 300),
          delay: Duration(milliseconds: index * 50),
          child: _buildConfigCard(config, state.catalogoCuentas, isDesktop),
        );
      },
    );
  }

  Widget _buildConfigCard(
    ConfiguracionContableModel config,
    List<CatalogoCuentaModel> accounts,
    bool isDesktop,
  ) {
    // Determine if modified locally
    final isModified = _localChanges.containsKey(config.id);
    final int? selectedAccountId = isModified
        ? _localChanges[config.id]
        : config.cuentaId;

    // Get selected account model
    final selectedAccount = selectedAccountId != null
        ? accounts.where((acc) => acc.id == selectedAccountId).firstOrNull
        : null;

    final isDebit = config.clave.endsWith('_debe');

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: isModified
              ? AppColors.primary.withValues(alpha: 0.5)
              : Colors.transparent,
          width: isModified ? 1.5 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Left Side: Role details
            Expanded(
              flex: 3,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isDebit
                          ? AppColors.success.withValues(alpha: 0.1)
                          : AppColors.info.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      isDebit
                          ? Icons.arrow_upward_rounded
                          : Icons.arrow_downward_rounded,
                      color: isDebit ? AppColors.success : AppColors.info,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              config.nombre,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.azulOscuro,
                              ),
                            ),
                            if (isModified) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'MODIFICADO',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _getHelperDescription(config.clave),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 24),

            // Right Side: Selector Dropdown Card
            Expanded(
              flex: 2,
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () => _showAccountSearchSelector(
                    accounts: accounts,
                    configId: config.id,
                    currentAccountId: selectedAccountId,
                    configName: config.nombre,
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: selectedAccount != null
                            ? AppColors.azulOscuro.withValues(alpha: 0.1)
                            : Colors.grey.shade300,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: selectedAccount != null
                              ? Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      selectedAccount.nombre,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.azulOscuro,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Código: ${selectedAccount.codigo}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                )
                              : Text(
                                  'Sin asignar (Seleccionar...)',
                                  style: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontSize: 13,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.swap_vert_circle_rounded,
                          color: AppColors.primary,
                          size: 24,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getHelperDescription(String key) {
    switch (key) {
      // Ventas
      case 'venta_efectivo_debe':
        return 'Cuenta de activo que registra el efectivo recaudado en las ventas del día (ej. Caja General).';
      case 'venta_credito_debe':
        return 'Cuenta de activo que controla los saldos pendientes de cobrar a clientes con crédito (ej. Cuentas por Cobrar).';
      case 'venta_haber':
        return 'Cuenta de ingresos operativos donde se acumula la facturación de comidas y bebidas (ej. Ventas de Alimentos).';
      case 'venta_itbis_haber':
        return 'Cuenta de pasivo corriente que acumula el impuesto ITBIS cobrado al cliente para declarar a la DGII (ej. ITBIS por Pagar).';

      // Compras
      case 'compra_inventario_debe':
        return 'Cuenta de activo realizable que debita la materia prima e ingredientes comprados (ej. Inventario de Alimentos).';
      case 'compra_proveedor_haber':
        return 'Cuenta de pasivo que registra las obligaciones comerciales con proveedores (ej. Cuentas por Pagar Proveedores).';
      case 'compra_itbis_debe':
        return 'Cuenta de impuesto en compras que registra el ITBIS pagado para compensar (ej. ITBIS por Pagar/Adelantado).';

      // Nómina
      case 'nomina_gasto_debe':
        return 'Cuenta de gastos operativos para acumular el costo de sueldos pagados al personal (ej. Nómina y Salarios).';
      case 'nomina_pago_haber':
        return 'Cuenta bancaria de donde se extraen los fondos para transferir los salarios netos (ej. Banco Operativo).';

      default:
        return 'Configuración contable automática del sistema de restaurante.';
    }
  }
}
