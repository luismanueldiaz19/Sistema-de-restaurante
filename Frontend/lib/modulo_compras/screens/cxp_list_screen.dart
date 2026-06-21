import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../palletes/app_colors.dart';
import '../providers/cxp_provider.dart';
import '../models/cxp.dart';
import '../../utils/helpers.dart';
import 'widgets/cxp_detalle_pago_panel.dart';

class CxpListScreen extends ConsumerStatefulWidget {
  const CxpListScreen({super.key});

  @override
  ConsumerState<CxpListScreen> createState() => _CxpListScreenState();
}

class _CxpListScreenState extends ConsumerState<CxpListScreen> {
  CuentaPorPagar? _selectedCxp;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(cxpProvider.notifier).loadCxps();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(cxpProvider);

    return Scaffold(
      backgroundColor: AppColors.light,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Cuentas por Pagar',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: AppColors.secondary,
              ),
            ),
            Text(
              'Gestión de pagos y obligaciones',
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
              : _buildDashboard(state.cxps),
    );
  }

  Widget _buildDashboard(List<CuentaPorPagar> cxps) {
    final pendientes = cxps.where((c) => c.balancePendiente > 0).toList();
    final totalDeuda = pendientes.fold(0.0, (sum, c) => sum + c.balancePendiente);

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
              'No tienes cuentas por pagar pendientes.',
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
                        gradient: const LinearGradient(
                          colors: [AppColors.primary, AppColors.secondary],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.3),
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
                              color: Colors.white.withOpacity(0.2),
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
                                'Deuda Total Pendiente',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                formatCurrency(totalDeuda),
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
                          final cxp = pendientes[index];
                          final isVencida = cxp.fechaVencimiento.isBefore(DateTime.now());
                          final isSelected = _selectedCxp?.id == cxp.id;

                          return InkWell(
                            onTap: () {
                              setState(() {
                                _selectedCxp = cxp;
                              });
                              if (!isTablet) {
                                // En móviles podríamos mostrar un BottomSheet o navegar. 
                                // Por simplicidad, abriremos un bottom sheet
                                showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                  builder: (ctx) => Padding(
                                    padding: EdgeInsets.only(top: MediaQuery.of(ctx).padding.top + 20),
                                    child: CxpDetalleYPagoPanel(
                                      cxp: cxp,
                                      onPagoCompletado: () {
                                        Navigator.pop(ctx);
                                        setState(() {
                                          _selectedCxp = null;
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
                                color: isSelected ? AppColors.primary.withOpacity(0.05) : Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.primary
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
                                                color: AppColors.primary.withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: const Icon(
                                                Icons.receipt_long,
                                                color: AppColors.primary,
                                                size: 20,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  cxp.proveedor?.nombre ?? 'Proveedor Desconocido',
                                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                                ),
                                                Text(
                                                  'Factura Nº ${cxp.compra?.numeroFacturaProveedor ?? 'N/A'}',
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
                                              cxp.fechaVencimiento.toLocal().toString().split(' ')[0],
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
                                              formatCurrency(cxp.balancePendiente),
                                              style: const TextStyle(
                                                color: AppColors.danger,
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

              // PANEL DERECHO (Detalle y Pago)
              if (isTablet)
                Expanded(
                  flex: 4,
                  child: CxpDetalleYPagoPanel(
                    cxp: _selectedCxp,
                    onPagoCompletado: () {
                      setState(() {
                        _selectedCxp = null;
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
