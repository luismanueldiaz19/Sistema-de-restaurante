import 'package:flutter/material.dart';
import '../../palletes/app_colors.dart';

class DialogInstruccionesImportacion extends StatelessWidget {
  final VoidCallback onImport;

  const DialogInstruccionesImportacion({
    super.key,
    required this.onImport,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      title: const Text(
        'Importar Productos Masivamente',
        style: TextStyle(
          color: AppColors.azulOscuro,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: SizedBox(
        width: double.maxFinite, 
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Para cargar productos, debes subir un archivo de Excel (.xlsx, .xls) o CSV.\n'
                'La primera fila debe contener exactamente estos encabezados (en minúsculas):',
              ),
              const SizedBox(height: 15),
              _buildExcelPreviewTable(),
              const SizedBox(height: 15),
              const Text(
                'Valores permitidos:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 5),
              const Text(
                '• tipo_producto: PRODUCTO, SERVICIO, COMBO, MATERIA_PRIMA\n'
                '• tipo_contable: INVENTARIO, GASTO, ACTIVO_FIJO, SERVICIO\n'
                '• maneja_inventario: true, false',
                style: TextStyle(fontSize: 13, height: 1.5),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            'Cancelar',
            style: TextStyle(color: Colors.grey),
          ),
        ),
        ElevatedButton.icon(
          onPressed: () {
            Navigator.pop(context);
            onImport();
          },
          icon: const Icon(Icons.upload_file, size: 18),
          label: const Text('Seleccionar Archivo'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.azulOscuro,
            foregroundColor: Colors.white,
          ),
        ),
      ],
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
          child: Theme(
            data: ThemeData(
              dataTableTheme: DataTableThemeData(
                headingRowColor: MaterialStateProperty.all(const Color(0xFFE3F2FD)), // Un azul claro estilo Excel
              ),
            ),
            child: DataTable(
              headingTextStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
                fontSize: 12,
              ),
              dataTextStyle: const TextStyle(
                fontSize: 12,
                color: Colors.black87,
              ),
              columnSpacing: 20,
              horizontalMargin: 12,
              columns: const [
                DataColumn(label: Text('nombre')),
                DataColumn(label: Text('codigo')),
                DataColumn(label: Text('descripcion')),
                DataColumn(label: Text('tipo_producto')),
                DataColumn(label: Text('tipo_contable')),
                DataColumn(label: Text('precio_venta')),
                DataColumn(label: Text('ultimo_costo')),
                DataColumn(label: Text('impuesto_id')),
                DataColumn(label: Text('stock_minimo')),
                DataColumn(label: Text('maneja_inventario')),
              ],
              rows: const [
                DataRow(cells: [
                  DataCell(Text('WHISKY MACK ABEL 350 ML')),
                  DataCell(Text('WH-02')),
                  DataCell(Text('WHISKY')),
                  DataCell(Text('PRODUCTO')),
                  DataCell(Text('INVENTARIO')),
                  DataCell(Text('350')),
                  DataCell(Text('252.55')),
                  DataCell(Text('1')),
                  DataCell(Text('6')),
                  DataCell(Text('true')),
                ]),
                DataRow(cells: [
                  DataCell(Text('CIGARRILLO VICEROL')),
                  DataCell(Text('CVPM-01')),
                  DataCell(Text('CIGARRILLO')),
                  DataCell(Text('PRODUCTO')),
                  DataCell(Text('INVENTARIO')),
                  DataCell(Text('12.5')),
                  DataCell(Text('7.2')),
                  DataCell(Text('1')),
                  DataCell(Text('6')),
                  DataCell(Text('true')),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
