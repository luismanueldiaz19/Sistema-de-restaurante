import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../palletes/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../utils/helpers.dart';
import '../services/facturacion_service.dart';
import '../../widgets/custom_loading.dart';

class ReporteVentasScreen extends ConsumerStatefulWidget {
  const ReporteVentasScreen({super.key});

  @override
  ConsumerState<ReporteVentasScreen> createState() =>
      _ReporteVentasScreenState();
}

class _ReporteVentasScreenState extends ConsumerState<ReporteVentasScreen> {
  final FacturacionService _service = FacturacionService();
  bool _isLoading = true;
  Map<String, dynamic> _data = {};
  String? _error;

  final TextEditingController _desdeController = TextEditingController(
    text: DateTime.now().toIso8601String().split('T')[0],
  );
  final TextEditingController _hastaController = TextEditingController(
    text: DateTime.now().toIso8601String().split('T')[0],
  );

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final auth = ref.read(authProvider);
    try {
      final result = await _service.getReportes(
        token: auth.token!,
        fechaDesde: _desdeController.text,
        fechaHasta: _hastaController.text,
      );

      if (mounted) {
        if (result['success']) {
          setState(() {
            _data = result['data'];
            _isLoading = false;
          });
        } else {
          setState(() {
            _error = result['message'];
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = "Excepción en UI: $e";
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'REPORTES DE VENTAS',
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: -0.5),
        ),
        actions: [
          IconButton(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterPanel(),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CustomLoading(text: 'Generando reportes...'),
                  )
                : _error != null
                ? Center(child: Text('Error: $_error'))
                : _buildReportContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterPanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(16),
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
      child: Row(
        children: [
          Expanded(
            child: textFieldWidgetUI(
              label: 'Desde',
              hintText: 'AAAA-MM-DD',
              controller: _desdeController,
              readOnly: true,
              onTap: () => _selectDate(_desdeController),
              prefixIcon: Icons.calendar_today_rounded,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: textFieldWidgetUI(
              label: 'Hasta',
              hintText: 'AAAA-MM-DD',
              controller: _hastaController,
              readOnly: true,
              onTap: () => _selectDate(_hastaController),
              prefixIcon: Icons.calendar_today_rounded,
            ),
          ),
          const SizedBox(width: 16),
          ElevatedButton.icon(
            onPressed: _loadData,
            icon: const Icon(Icons.search, color: Colors.white),
            label: const Text('FILTRAR', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate(TextEditingController controller) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        controller.text = picked.toIso8601String().split('T')[0];
      });
      _loadData();
    }
  }

  Widget _buildReportContent() {
    final porMetodo = _data['por_metodo'] as List? ?? [];
    final porCajero = _data['por_cajero'] as List? ?? [];
    final porTipo = _data['por_tipo'] as List? ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildGroupCard(
                  title: 'VENTAS POR MÉTODO DE PAGO',
                  icon: Icons.payments_rounded,
                  items: porMetodo,
                  labelKey: 'metodo_pago',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildGroupCard(
                  title: 'VENTAS POR TIPO (CRÉDITO/CONTADO)',
                  icon: Icons.receipt_long_rounded,
                  items: porTipo,
                  labelKey: 'tipo_factura',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildGroupCard(
            title: 'VENTAS AGRUPADAS POR CAJERO',
            icon: Icons.people_alt_rounded,
            items: porCajero,
            labelKey: 'cajero',
            isWide: true,
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildGroupCard({
    required String title,
    required IconData icon,
    required List items,
    required String labelKey,
    bool isWide = false,
  }) {
    double totalGeneral = 0;
    for (var item in items) {
      totalGeneral += double.parse(item['total'].toString());
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                  color: AppColors.azulOscuro,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (items.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  'No hay datos en este rango',
                  style: TextStyle(
                    color: Colors.grey,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            )
          else
            Table(
              columnWidths: const {
                0: FlexColumnWidth(2),
                1: IntrinsicColumnWidth(),
                2: IntrinsicColumnWidth(),
              },
              children: [
                TableRow(
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.grey.shade100),
                    ),
                  ),
                  children: const [
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'CONCEPTO',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 16,
                      ),
                      child: Text(
                        'CANT.',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'TOTAL',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
                ...items.map((item) {
                  final label =
                      item[labelKey]?.toString().toUpperCase() ?? 'N/A';
                  final cantidad = item['cantidad'].toString();
                  final total = double.parse(item['total'].toString());
                  return TableRow(
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Colors.grey.shade50),
                      ),
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          label,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 16,
                        ),
                        child: Text(
                          cantidad,
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          formatCurrency(total),
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  );
                }),
                TableRow(
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        'TOTAL GENERAL',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        formatCurrency(totalGeneral),
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          color: AppColors.azulOscuro,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
        ],
      ),
    );
  }
}
