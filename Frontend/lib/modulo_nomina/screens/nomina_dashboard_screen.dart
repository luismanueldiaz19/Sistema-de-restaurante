import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../palletes/app_colors.dart';
import '../../utils/helpers.dart';
import '../models/nomina_model.dart';
import '../providers/nomina_provider.dart';
import '../providers/nomina_state.dart';
import 'add_nomina_screen.dart';
import 'nomina_detail_screen.dart';
import 'empleado_list_screen.dart';

class NominaDashboardScreen extends ConsumerStatefulWidget {
  const NominaDashboardScreen({super.key});

  @override
  ConsumerState<NominaDashboardScreen> createState() =>
      _NominaDashboardScreenState();
}

class _NominaDashboardScreenState extends ConsumerState<NominaDashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Cargar datos iniciales
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ref.read(nominaProvider.notifier).canAccess()) {
        ref.read(nominaProvider.notifier).fetchHistorial();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final canAccess = ref.watch(nominaProvider.notifier).canAccess();

    if (!canAccess) {
      return Scaffold(
        appBar: AppBar(title: const Text('Módulo de Nómina')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                'Acceso Denegado',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Solo personal de contabilidad o administradores\npueden acceder a este módulo.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Volver'),
              ),
            ],
          ),
        ),
      );
    }

    final state = ref.watch(nominaProvider);

    double totalCosto = state.historialNominas.fold(
      0,
      (a, b) => a + (b.totalNeto ?? 0),
    );
    double totalTSS = state.historialNominas.fold(
      0,
      (a, b) => a + (b.totalRetenciones ?? 0),
    );
    double totalISR = state.historialNominas.fold(
      0,
      (a, b) => a + (b.detalles.fold(0, (x, y) => x + (y.isrRetencion ?? 0))),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Nómina'),
        backgroundColor: AppColors.azulOscuro,
        foregroundColor: Colors.white,
      ),
      body: state.isLoading && state.historialNominas.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 📊 Tarjetas de Métricas
                  Row(
                    children: [
                      Expanded(
                        child: _SummaryCard(
                          title: 'Empleados',
                          value: '${state.empleados.length}',
                          icon: Icons.people_outline,
                          color: Colors.blue,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const EmpleadoListScreen(),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: _SummaryCard(
                          title: 'Total Neto Mes',
                          value: formatCurrency(totalCosto),
                          icon: Icons.account_balance_wallet_outlined,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      Expanded(
                        child: _SummaryCard(
                          title: 'TSS a Pagar',
                          value: formatCurrency(totalTSS),
                          icon: Icons.security_outlined,
                          color: Colors.indigo,
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: _SummaryCard(
                          title: 'ISR Retenido',
                          value: formatCurrency(totalISR),
                          icon: Icons.account_balance_outlined,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  const Text(
                    'Historial de Nóminas',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  state.historialNominas.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(40),
                          child: Center(
                            child: Text('No hay nóminas registradas.'),
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: state.historialNominas.length,
                          itemBuilder: (context, index) {
                            final nomina = state.historialNominas[index];
                            return _NominaTile(nomina: nomina);
                          },
                        ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await showDialog(
            context: context,
            builder: (_) => const AddNominaDialog(),
          );
          if (result == true && context.mounted) {
            ref.read(nominaProvider.notifier).fetchHistorial();
          }
        },
        backgroundColor: AppColors.secondary,
        icon: const Icon(Icons.add),
        label: const Text('Nueva Nómina'),
      ),
    );
  }

  Widget _buildSummaryCards(NominaState state) {
    return Row(
      children: [
        Expanded(
          child: _SummaryCard(
            title: 'Empleados',
            value: state.empleados.length.toString(),
            icon: Icons.people_outline,
            color: AppColors.azulOscuro,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const EmpleadoListScreen()),
              );
            },
          ),
        ),
        const SizedBox(width: 16),
        const Expanded(
          child: _SummaryCard(
            title: 'Costo Mensual',
            value: 'RD\$ 0.00',
            icon: Icons.account_balance_wallet_outlined,
            color: Colors.green,
          ),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NominaTile extends StatelessWidget {
  final NominaModel nomina;

  const _NominaTile({required this.nomina});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.azulOscuro.withOpacity(0.1),
          child: const Icon(
            Icons.description_outlined,
            color: AppColors.azulOscuro,
          ),
        ),
        title: Text(
          'Periodo: ${nomina.periodo}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          'Total Neto: ${formatCurrency(nomina.totalNeto)} • Estado: ${nomina.estado}',
          style: const TextStyle(fontSize: 12),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => NominaDetailScreen(nomina: nomina),
            ),
          );
        },
      ),
    );
  }
}
