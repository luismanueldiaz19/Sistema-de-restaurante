import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../palletes/app_colors.dart';
import '../providers/dgii_provider.dart';

class DgiiPreviewScreen extends ConsumerStatefulWidget {
  final String tipoReporte; // '606' o '607'
  final String mes;
  final String anio;

  const DgiiPreviewScreen({
    super.key,
    required this.tipoReporte,
    required this.mes,
    required this.anio,
  });

  @override
  ConsumerState<DgiiPreviewScreen> createState() => _DgiiPreviewScreenState();
}

class _DgiiPreviewScreenState extends ConsumerState<DgiiPreviewScreen> {
  final formatC = NumberFormat.currency(symbol: '\$');
  bool isLoading = true;
  String? error;
  List<dynamic> datos = [];

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    try {
      final res = await ref
          .read(dgiiProvider.notifier)
          .fetchPreview(widget.tipoReporte, widget.mes, widget.anio);
      if (mounted) {
        setState(() {
          datos = res;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          error = e.toString();
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          'Vista Previa Formato ${widget.tipoReporte}',
          style: const TextStyle(color: AppColors.azulOscuro, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: AppColors.azulOscuro),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: ElevatedButton.icon(
              onPressed: () {
                if (widget.tipoReporte == '606') {
                  ref.read(dgiiProvider.notifier).exportar606(widget.mes, widget.anio);
                } else {
                  ref.read(dgiiProvider.notifier).exportar607(widget.mes, widget.anio);
                }
              },
              icon: const Icon(Icons.download, size: 18),
              label: const Text('Confirmar y Exportar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (error != null) {
      return Center(
        child: Text('Error: $error', style: const TextStyle(color: Colors.red)),
      );
    }
    if (datos.isEmpty) {
      return const Center(
        child: Text('No hay registros en este período para exportar.'),
      );
    }

    final columnLabel1 = widget.tipoReporte == '606' ? 'Proveedor' : 'Cliente';

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SingleChildScrollView(
              child: DataTable(
                headingRowColor: MaterialStateProperty.all(AppColors.primary.withOpacity(0.1)),
                columns: [
                  const DataColumn(label: Text('RNC/Cédula', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text(columnLabel1, style: const TextStyle(fontWeight: FontWeight.bold))),
                  const DataColumn(label: Text('NCF', style: TextStyle(fontWeight: FontWeight.bold))),
                  const DataColumn(label: Text('Fecha', style: TextStyle(fontWeight: FontWeight.bold))),
                  const DataColumn(label: Text('Subtotal', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
                  const DataColumn(label: Text('ITBIS', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
                  const DataColumn(label: Text('Total', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
                ],
                rows: datos.map((d) {
                  return DataRow(cells: [
                    DataCell(Text(d['rnc'] ?? '')),
                    DataCell(Text(d['nombre'] ?? '')),
                    DataCell(Text(d['ncf'] ?? '')),
                    DataCell(Text(d['fecha'] ?? '')),
                    DataCell(Text(formatC.format(d['subtotal'] ?? 0))),
                    DataCell(Text(formatC.format(d['itbis'] ?? 0))),
                    DataCell(Text(formatC.format(d['total'] ?? 0))),
                  ]);
                }).toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
