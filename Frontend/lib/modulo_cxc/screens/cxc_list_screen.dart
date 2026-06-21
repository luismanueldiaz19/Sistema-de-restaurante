import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../palletes/app_colors.dart';
import '../providers/cxc_provider.dart';
import '../models/cxc.dart';
import '../../utils/helpers.dart';
import 'widgets/cxc_detalle_cobro_panel.dart';

class CxcListScreen extends ConsumerStatefulWidget {
  const CxcListScreen({super.key});

  @override
  ConsumerState<CxcListScreen> createState() => _CxcListScreenState();
}

class _CxcListScreenState extends ConsumerState<CxcListScreen> {
  CuentaPorCobrar? _selectedCxc;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(cxcProvider.notifier).loadCxcs();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(cxcProvider);

    return Scaffold(
      backgroundColor: AppColors.light,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Cuentas por Cobrar',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: AppColors.secondary,
              ),
            ),
            Text(
              'Gestión de cobros a clientes',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
          ],
        ),
        iconTheme: const IconThemeData(color: AppColors.secondary),
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : (state.error != null && state.error!.isNotEmpty)
              ? Center(
                  child: Text(
                    'Error: ${state.error}',
                    style: const TextStyle(color: AppColors.danger),
                  ),
                )
              : _buildDashboard(state.cxcs),
    );
  }

  Widget _buildDashboard(List<CuentaPorCobrar> cxcs) {
    final pendientes = cxcs.where((c) => c.balancePendiente > 0).toList();
    final totalCobrar = pendientes.fold(0.0, (sum, c) => sum + c.balancePendiente);

    if (pendientes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 80, color: Colors.green.shade200),
            const SizedBox(height: 16),
            const Text(
              '¡Todo al día!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.secondary),
            ),
            Text(
              'No tienes cuentas por cobrar pendientes.',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isTablet = constraints.maxWidth > 800;

        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // PANEL IZQUIERDO (Lista)
              Expanded(
                flex: 5,
                child: Column(
                  children: [
                    // Resumen
                    Container(
                      margin: const EdgeInsets.only(bottom: 24),
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.green.shade700, Colors.teal.shade800],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.withValues(alpha: 0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.account_balance_wallet_outlined,
                              color: Colors.white,
                              size: 40,
                            ),
                          ),
                          const SizedBox(width: 20),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Total por Cobrar',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.8),
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                formatCurrency(totalCobrar),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 32,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Lista de facturas
                    Expanded(
                      child: ListView.builder(
                        itemCount: pendientes.length,
                        itemBuilder: (context, index) {
                          final cxc = pendientes[index];
                          final isVencida = cxc.fechaVencimiento?.isBefore(DateTime.now()) ?? false;
                          final isSelected = _selectedCxc?.id == cxc.id;

                          return InkWell(
                            onTap: () {
                              setState(() {
                                _selectedCxc = cxc;
                              });
                              if (!isTablet) {
                                showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                  builder: (ctx) => Padding(
                                    padding: EdgeInsets.only(top: MediaQuery.of(ctx).padding.top + 20),
                                    child: CxcDetalleCobroPanel(
                                      cxc: cxc,
                                      onCobroCompletado: () {
                                        Navigator.pop(ctx);
                                        setState(() {
                                          _selectedCxc = null;
                                        });
                                      },
                                    ),
                                  ),
                                );
                              }
                            },
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: isSelected ? Colors.green.withValues(alpha: 0.05) : Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isSelected
                                      ? Colors.green
                                      : isVencida
                                          ? Colors.red.shade200
                                          : Colors.grey.shade200,
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(10),
                                              decoration: BoxDecoration(
                                                color: Colors.green.withValues(alpha: 0.1),
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: const Icon(
                                                Icons.receipt_long,
                                                color: Colors.green,
                                                size: 20,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  cxc.cliente?['nombre'] ?? 'Cliente Desconocido',
                                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                                ),
                                                Text(
                                                  'Factura NCF ${cxc.factura?['ncf'] ?? 'N/A'}',
                                                  style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                        if (isVencida)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: Colors.red.shade50,
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: const Text(
                                              'VENCIDA',
                                              style: TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 20),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text('Vencimiento', style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
                                            Text(
                                              cxc.fechaVencimiento?.toLocal().toString().split(' ')[0] ?? 'N/A',
                                              style: TextStyle(
                                                color: isVencida ? Colors.red : Colors.black87,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            Text('Balance', style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
                                            Text(
                                              formatCurrency(cxc.balancePendiente),
                                              style: const TextStyle(
                                                color: Colors.green,
                                                fontWeight: FontWeight.w900,
                                                fontSize: 18,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),

              if (isTablet) const SizedBox(width: 24),

              // PANEL DERECHO (Detalle y Cobro)
              if (isTablet)
                Expanded(
                  flex: 4,
                  child: CxcDetalleCobroPanel(
                    cxc: _selectedCxc,
                    onCobroCompletado: () {
                      setState(() {
                        _selectedCxc = null;
                      });
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
