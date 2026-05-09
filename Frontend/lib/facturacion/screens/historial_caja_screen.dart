import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../palletes/app_colors.dart';
import '../../utils/helpers.dart';
import '../../providers/auth_provider.dart';
import '../../modulo_caja/providers/caja_provider.dart';

class HistorialCajaScreen extends ConsumerStatefulWidget {
  const HistorialCajaScreen({super.key});

  @override
  ConsumerState<HistorialCajaScreen> createState() =>
      _HistorialCajaScreenState();
}

class _HistorialCajaScreenState extends ConsumerState<HistorialCajaScreen> {
  final _fechaDesdeController = TextEditingController();
  final _fechaHastaController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final token = ref.read(authProvider).token;
      if (token != null) {
        ref.read(cajaProvider.notifier).fetchHistorial(token);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(cajaProvider);
    final auth = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('HISTORIAL DE CIERRES DE CAJA'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.azulOscuro,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {
              if (auth.token != null) {
                ref.read(cajaProvider.notifier).fetchHistorial(auth.token!);
              }
            },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilters(auth.token, state),
          Expanded(
            child: state.isLoading && state.historial.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : _buildTable(state.historial),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters(String? token, CajaState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: textFieldWidgetUI(
              label: 'Fecha Desde',
              controller: _fechaDesdeController,
              readOnly: true,
              prefixIcon: Icons.calendar_today,
              onTap: () async {
                final date = await showCustomDatePicker(context);
                if (date != null && token != null) {
                  final formatted = formatDate(date);
                  _fechaDesdeController.text = formatted;
                  ref.read(cajaProvider.notifier).updateFilters(token, {
                    'fecha_desde': formatted,
                  });
                }
              },
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: textFieldWidgetUI(
              label: 'Fecha Hasta',
              controller: _fechaHastaController,
              readOnly: true,
              prefixIcon: Icons.calendar_today,
              onTap: () async {
                final date = await showCustomDatePicker(context);
                if (date != null && token != null) {
                  final formatted = formatDate(date);
                  _fechaHastaController.text = formatted;
                  ref.read(cajaProvider.notifier).updateFilters(token, {
                    'fecha_hasta': formatted,
                  });
                }
              },
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFE0E0E0)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: state.filters['estado'],
                  hint: const Text('Estado'),
                  isExpanded: true,
                  items: const [
                    DropdownMenuItem(value: null, child: Text('Todos')),
                    DropdownMenuItem(value: 'abierta', child: Text('Abierta')),
                    DropdownMenuItem(value: 'cerrada', child: Text('Cerrada')),
                  ],
                  onChanged: (val) {
                    if (token != null) {
                      if (val == null) {
                        final newFilters = Map<String, String>.from(
                          state.filters,
                        );
                        newFilters.remove('estado');
                        ref
                            .read(cajaProvider.notifier)
                            .updateFilters(token, newFilters, replace: true);
                      } else {
                        ref.read(cajaProvider.notifier).updateFilters(token, {
                          'estado': val,
                        });
                      }
                    }
                  },
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          ElevatedButton.icon(
            onPressed: () {
              if (token != null) {
                _fechaDesdeController.clear();
                _fechaHastaController.clear();
                ref.read(cajaProvider.notifier).clearFilters(token);
              }
            },
            icon: const Icon(Icons.clear_all),
            label: const Text('Limpiar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey.shade200,
              foregroundColor: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTable(List<dynamic> sessions) {
    if (sessions.isEmpty) {
      return const Center(child: Text('No se encontraron cierres de caja.'));
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SizedBox(
        width: double.infinity,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: MaterialStateProperty.all(
              AppColors.azulOscuro.withOpacity(0.05),
            ),
            columns: const [
              DataColumn(
                label: Text(
                  'ID',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  'Caja',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  'Turno',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  'Apertura',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  'Cierre',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  'Fondo Inicial',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  'Físico',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  'Diferencia',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  'Estado',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  'Acciones',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
            rows: sessions.map((s) {
              final double diff = double.parse(
                (s['diferencia'] ?? 0).toString(),
              );
              final double montoInicial = double.parse(
                (s['monto_inicial'] ?? 0).toString(),
              );
              final double? montoFisico = s['monto_final_fisico'] != null
                  ? double.parse(s['monto_final_fisico'].toString())
                  : null;

              return DataRow(
                cells: [
                  DataCell(Text('#${s['id']}')),
                  DataCell(Text(s['caja']?['nombre'] ?? 'N/A')),
                  DataCell(Text(s['turno']?['nombre'] ?? 'N/A')),
                  DataCell(
                    Text(formatFechaHora(DateTime.parse(s['fecha_apertura']))),
                  ),
                  DataCell(
                    Text(
                      s['fecha_cierre'] != null
                          ? formatFechaHora(DateTime.parse(s['fecha_cierre']))
                          : 'Pendiente',
                    ),
                  ),
                  DataCell(Text(formatCurrency(montoInicial))),
                  DataCell(
                    Text(
                      montoFisico != null ? formatCurrency(montoFisico) : '-',
                    ),
                  ),
                  DataCell(
                    Text(
                      formatCurrency(diff),
                      style: TextStyle(
                        color: diff == 0
                            ? Colors.green
                            : (diff > 0 ? Colors.blue : Colors.red),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: s['estado'] == 'abierta'
                            ? Colors.green.shade100
                            : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        s['estado'].toString().toUpperCase(),
                        style: TextStyle(
                          color: s['estado'] == 'abierta'
                              ? Colors.green.shade800
                              : Colors.grey.shade800,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  DataCell(
                    IconButton(
                      icon: const Icon(
                        Icons.visibility_outlined,
                        color: AppColors.azulOscuro,
                      ),
                      onPressed: () => _showDetalles(context, s),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  void _showDetalles(BuildContext context, dynamic s) {
    final resumen = s['resumen_ventas'];
    final desglose = s['desglose_efectivo'] as Map<String, dynamic>?;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.history_rounded, color: AppColors.primary),
            const SizedBox(width: 12),
            Text('Detalle de Sesión #${s['id']}'),
          ],
        ),
        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle('INFORMACIÓN GENERAL'),
                _detalleItem('Cajero:', s['usuario']?['name'] ?? 'N/A'),
                _detalleItem('Caja:', s['caja']?['nombre'] ?? 'N/A'),
                _detalleItem('Turno:', s['turno']?['nombre'] ?? 'N/A'),
                _detalleItem(
                  'Apertura:',
                  formatFechaHora(DateTime.parse(s['fecha_apertura'])),
                ),
                if (s['fecha_cierre'] != null)
                  _detalleItem(
                    'Cierre:',
                    formatFechaHora(DateTime.parse(s['fecha_cierre'])),
                  ),
                const SizedBox(height: 20),
                _buildSectionTitle('RESULTADOS FINANCIEROS'),
                _detalleItem(
                  'Monto Inicial:',
                  formatCurrency(
                    double.parse((s['monto_inicial'] ?? 0).toString()),
                  ),
                ),
                _detalleItem(
                  'Monto Esperado:',
                  formatCurrency(
                    double.parse((s['monto_final_esperado'] ?? 0).toString()),
                  ),
                ),
                _detalleItem(
                  'Monto Físico:',
                  s['monto_final_fisico'] != null
                      ? formatCurrency(
                          double.parse(s['monto_final_fisico'].toString()),
                        )
                      : '-',
                ),
                _detalleItem(
                  'Diferencia:',
                  formatCurrency(
                    double.parse((s['diferencia'] ?? 0).toString()),
                  ),
                  color: double.parse((s['diferencia'] ?? 0).toString()) < 0
                      ? Colors.red
                      : Colors.green,
                ),
                if (resumen != null) ...[
                  const SizedBox(height: 20),
                  _buildSectionTitle('RESUMEN DE VENTAS POR MÉTODO'),
                  ...(resumen as List).map((m) => _detalleItem(
                        m['metodo_pago'].toString().toUpperCase(),
                        formatCurrency(double.parse(m['total'].toString())),
                      )),
                ],
                if (desglose != null && desglose.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  _buildSectionTitle('DESGLOSE DE EFECTIVO (ARQUEO)'),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: desglose.entries.where((e) => e.value > 0).map((e) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Text(
                          'RD\$ ${e.key} x ${e.value}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
                const SizedBox(height: 20),
                _buildSectionTitle('OBSERVACIONES'),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Text(
                    s['comentario'] ?? 'Sin comentarios registrados.',
                    style: const TextStyle(fontStyle: FontStyle.italic),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.azulOscuro,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('CERRAR'),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w900,
          color: Colors.grey.shade600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _detalleItem(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: color ?? AppColors.azulOscuro,
            ),
          ),
        ],
      ),
    );
  }
}
