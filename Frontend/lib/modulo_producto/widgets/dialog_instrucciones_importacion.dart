import 'package:flutter/material.dart';
import '../../palletes/app_colors.dart';

class DialogInstruccionesImportacion extends StatelessWidget {
  final VoidCallback onImport;
  final VoidCallback onDownloadTemplate;

  const DialogInstruccionesImportacion({
    super.key,
    required this.onImport,
    required this.onDownloadTemplate,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 780),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.azulOscuro.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.inventory_2_outlined,
                          color: AppColors.azulOscuro,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Importación Masiva de Productos Inventariables',
                            style: TextStyle(
                              color: AppColors.azulOscuro,
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            'Descarga la plantilla base, agrega tus productos y previsualiza antes de confirmar.',
                            style: TextStyle(
                              color: Colors.black54,
                              fontSize: 11.5,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, size: 18),
                  ),
                ],
              ),
              const Divider(height: 20),

              // Reglas del sistema (Compact Cards)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildRuleBadge(
                    Icons.text_fields_rounded,
                    'Nombres en MAYÚSCULAS',
                    'Se convierten a UPPERCASE automáticamente',
                    Colors.blue.shade700,
                  ),
                  _buildRuleBadge(
                    Icons.qr_code_2_rounded,
                    'Código Autogenerado',
                    'Si dejas "codigo" vacío, el sistema lo genera',
                    Colors.teal.shade700,
                  ),
                  _buildRuleBadge(
                    Icons.fact_check_outlined,
                    'Control de Duplicados',
                    'Evita productos repetidos por nombre o código',
                    Colors.orange.shade800,
                  ),
                  _buildRuleBadge(
                    Icons.numbers_rounded,
                    'Verificación de Cantidad',
                    'Valida stock inicial, mínimo, costos y precios',
                    Colors.purple.shade700,
                  ),
                ],
              ),

              const SizedBox(height: 12),
              const Text(
                'Estructura de Columnas de la Plantilla Base:',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  color: AppColors.azulOscuro,
                ),
              ),
              const SizedBox(height: 6),
              _buildExcelPreviewTable(),

              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Valores de referencia rápida:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 11.5,
                        color: AppColors.azulOscuro,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '• tipo_producto: PRODUCTO (por defecto), MATERIA_PRIMA, PLATO, COMBO, SERVICIO\n'
                      '• tipo_contable: INVENTARIO (por defecto), GASTO, ACTIVO_FIJO, SERVICIO\n'
                      '• impuesto_id: 1 (ITBIS 18%), 2 (Exento 0%)  |  maneja_inventario: SI / NO (o true / false)',
                      style: TextStyle(
                        fontSize: 11,
                        height: 1.4,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Footer Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  OutlinedButton.icon(
                    onPressed: onDownloadTemplate,
                    icon: const Icon(Icons.download_rounded, size: 16),
                    label: const Text(
                      'Descargar Plantilla Base (.xlsx)',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.green.shade700,
                      side: BorderSide(color: Colors.green.shade600),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          'Cancelar',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          onImport();
                        },
                        icon: const Icon(Icons.visibility_outlined, size: 16),
                        label: const Text(
                          'Seleccionar Archivo y Previsualizar',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.azulOscuro,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
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
  }

  Widget _buildRuleBadge(
    IconData icon,
    String title,
    String subtitle,
    Color color,
  ) {
    return Container(
      width: 365,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 10, color: Colors.black54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExcelPreviewTable() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowHeight: 32,
            dataRowMinHeight: 28,
            dataRowMaxHeight: 32,
            headingRowColor: WidgetStateProperty.all(const Color(0xFFE3F2FD)),
            headingTextStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black87,
              fontSize: 11,
            ),
            dataTextStyle: const TextStyle(
              fontSize: 11,
              color: Colors.black87,
            ),
            columnSpacing: 16,
            horizontalMargin: 10,
            columns: const [
              DataColumn(label: Text('nombre *')),
              DataColumn(label: Text('codigo (opc)')),
              DataColumn(label: Text('categoria')),
              DataColumn(label: Text('unidad_medida')),
              DataColumn(label: Text('tipo_producto')),
              DataColumn(label: Text('precio_venta *')),
              DataColumn(label: Text('costo')),
              DataColumn(label: Text('stock_actual')),
              DataColumn(label: Text('stock_minimo')),
              DataColumn(label: Text('maneja_inventario')),
            ],
            rows: const [
              DataRow(
                cells: [
                  DataCell(Text('COCA COLA 20 OZ')),
                  DataCell(
                    Text(
                      '(vacío = auto)',
                      style: TextStyle(
                        color: Colors.teal,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                  DataCell(Text('Bebidas')),
                  DataCell(Text('BOT')),
                  DataCell(Text('PRODUCTO')),
                  DataCell(Text('75.00')),
                  DataCell(Text('45.00')),
                  DataCell(Text('24')),
                  DataCell(Text('6')),
                  DataCell(Text('SI')),
                ],
              ),
              DataRow(
                cells: [
                  DataCell(Text('AGUA DASANI 500 ML')),
                  DataCell(Text('AGU-0001')),
                  DataCell(Text('Bebidas')),
                  DataCell(Text('BOT')),
                  DataCell(Text('PRODUCTO')),
                  DataCell(Text('40.00')),
                  DataCell(Text('20.00')),
                  DataCell(Text('48')),
                  DataCell(Text('12')),
                  DataCell(Text('SI')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
