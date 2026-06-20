import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../palletes/app_colors.dart';
import '../providers/dgii_provider.dart';
import '../widgets/registrar_pago_dgii_dialog.dart';
import 'dgii_preview_screen.dart';
import 'package:intl/intl.dart';

class DgiiDashboardScreen extends ConsumerStatefulWidget {
  const DgiiDashboardScreen({super.key});

  @override
  ConsumerState<DgiiDashboardScreen> createState() =>
      _DgiiDashboardScreenState();
}

class _DgiiDashboardScreenState extends ConsumerState<DgiiDashboardScreen> {
  final formatC = NumberFormat.currency(symbol: '\$');

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(dgiiProvider.notifier).fetchDashboardData(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(dgiiProvider);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Obligaciones DGII',
          style: TextStyle(
            color: AppColors.azulOscuro,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: AppColors.azulOscuro),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: ElevatedButton.icon(
              onPressed: () {
                ref.read(dgiiProvider.notifier).fetchDashboardData();
              },
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Actualizar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 1, child: _buildBalanceCard(state)),
                  const SizedBox(width: 24),
                  Expanded(flex: 1, child: _buildReportesCard()),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                'Historial de Pagos',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height:
                    400, // Fixed height since it's inside SingleChildScrollView
                child: _buildPagosList(state),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBalanceCard(DgiiState state) {
    final isSaldoFavor = state.balanceItbis < 0;
    final absBalance = state.balanceItbis.abs();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isSaldoFavor
                    ? Icons.check_circle_outline
                    : Icons.warning_amber_rounded,
                color: isSaldoFavor ? Colors.green : Colors.redAccent,
                size: 28,
              ),
              const SizedBox(width: 8),
              const Text(
                'Balance ITBIS',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (state.isLoading)
            const CircularProgressIndicator()
          else
            Text(
              formatC.format(absBalance),
              style: TextStyle(
                fontSize: 42,
                fontWeight: FontWeight.w900,
                color: isSaldoFavor ? Colors.green : Colors.redAccent,
                letterSpacing: -1,
              ),
            ),
          const SizedBox(height: 8),
          Text(
            isSaldoFavor
                ? 'Tienes Saldo a Favor (DGII te debe)'
                : 'Monto Total por Pagar a la DGII',
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => const RegistrarPagoDgiiDialog(),
                );
              },
              icon: const Icon(Icons.payment),
              label: const Text(
                'REGISTRAR PAGO',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportesCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.file_present_rounded,
                color: AppColors.primary,
                size: 28,
              ),
              SizedBox(width: 8),
              Text(
                'Reportes Obligatorios',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Genera y descarga los archivos de texto requeridos por la Oficina Virtual de la DGII.',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _previewReport('606'),
                        icon: const Icon(Icons.visibility),
                        label: const Text('Previa 606 (Compras)'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: () => _exportReport('606'),
                      icon: const Icon(Icons.download_rounded, size: 16, color: Colors.grey),
                      label: const Text('Exportar Directo', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    )
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _previewReport('607'),
                        icon: const Icon(Icons.visibility),
                        label: const Text('Previa 607 (Ventas)'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: () => _exportReport('607'),
                      icon: const Icon(Icons.download_rounded, size: 16, color: Colors.grey),
                      label: const Text('Exportar Directo', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    )
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _exportReport(String type) {
    final now = DateTime.now();
    final mes = now.month.toString().padLeft(2, '0');
    final anio = now.year.toString();

    if (type == '606') {
      ref.read(dgiiProvider.notifier).exportar606(mes, anio);
    } else {
      ref.read(dgiiProvider.notifier).exportar607(mes, anio);
    }
  }

  void _previewReport(String type) {
    final now = DateTime.now();
    final mes = now.month.toString().padLeft(2, '0');
    final anio = now.year.toString();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DgiiPreviewScreen(tipoReporte: type, mes: mes, anio: anio),
      ),
    );
  }

  Widget _buildPagosList(DgiiState state) {
    if (state.isLoading && state.pagos.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.pagos.isEmpty) {
      return Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Text(
          'No hay pagos registrados',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: state.pagos.length,
        separatorBuilder: (_, __) => const Divider(),
        itemBuilder: (context, index) {
          final p = state.pagos[index];
          final monto = (p['monto_pagado'] as num).toDouble();

          return ListTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.primary.withOpacity(0.1),
              child: const Icon(Icons.receipt_long, color: AppColors.primary),
            ),
            title: Text(
              'Pago Período ${p["periodo_mes"]}/${p["periodo_anio"]}',
            ),
            subtitle: Text(
              'Fecha: ${p["fecha_pago"]} | Ref: ${p["referencia"] ?? "N/A"}\nDesde: ${p["cuenta_origen"]?["nombre"] ?? "Cuenta Desconocida"}',
            ),
            isThreeLine: true,
            trailing: Text(
              formatC.format(monto),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.green,
              ),
            ),
          );
        },
      ),
    );
  }
}
