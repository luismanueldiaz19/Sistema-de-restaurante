import 'package:flutter/material.dart';
import '../../palletes/app_colors.dart';
import '../../utils/formatter_number.dart';

class ContabilidadTreeSectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color accentColor;
  final List<dynamic> nodos;
  final double total;
  final List<Widget> extraBottomRows;

  const ContabilidadTreeSectionCard({
    super.key,
    required this.title,
    required this.icon,
    required this.accentColor,
    required this.nodos,
    required this.total,
    this.extraBottomRows = const [],
  });

  bool _hasVisibleData(Map<String, dynamic> nodo) {
    final balance = FormatterNumber.parseDouble(nodo['balance']);
    if (balance != 0) return true;
    final hijos = nodo['hijos'] as List<dynamic>?;
    if (hijos == null || hijos.isEmpty) return false;
    return hijos.any((h) => _hasVisibleData(Map<String, dynamic>.from(h)));
  }

  List<Widget> _buildNodes(List<dynamic> list, int depth) {
    final widgets = <Widget>[];
    for (final raw in list) {
      final nodo = Map<String, dynamic>.from(raw as Map);
      if (!_hasVisibleData(nodo)) continue;

      final esDetalle = nodo['es_detalle'] == true;
      final balance = FormatterNumber.parseDouble(nodo['balance']);
      final codigo = (nodo['codigo'] ?? '').toString();
      final nombre = (nodo['nombre'] ?? '').toString();
      final hijos = nodo['hijos'] as List<dynamic>?;

      widgets.add(
        Container(
          padding: EdgeInsets.only(
            left: 12 + (depth * 14.0),
            right: 12,
            top: 5.5,
            bottom: 5.5,
          ),
          decoration: BoxDecoration(
            color: !esDetalle && depth == 0
                ? Colors.grey.shade50
                : Colors.white,
            border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
          ),
          child: Row(
            children: [
              Icon(
                esDetalle
                    ? Icons.subdirectory_arrow_right_rounded
                    : Icons.folder_open_rounded,
                size: 14,
                color: esDetalle ? Colors.grey.shade400 : accentColor,
              ),
              const SizedBox(width: 6),
              if (codigo.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 1.5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    codigo,
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontFamily: 'Consolas',
                      fontWeight: FontWeight.w700,
                      color: AppColors.azulOscuro,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
              ],
              Expanded(
                child: Text(
                  nombre,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: esDetalle ? FontWeight.w500 : FontWeight.w700,
                    color: esDetalle
                        ? Colors.grey.shade800
                        : AppColors.azulOscuro,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                FormatterNumber.formatCurrency(balance),
                style: TextStyle(
                  fontSize: 11.5,
                  fontFamily: 'Consolas',
                  fontWeight: esDetalle ? FontWeight.w600 : FontWeight.w800,
                  color: balance < 0
                      ? Colors.red.shade700
                      : (esDetalle
                            ? Colors.grey.shade800
                            : AppColors.azulOscuro),
                ),
              ),
            ],
          ),
        ),
      );

      if (!esDetalle && hijos != null && hijos.isNotEmpty) {
        widgets.addAll(_buildNodes(hijos, depth + 1));
      }
    }
    return widgets;
  }

  @override
  Widget build(BuildContext context) {
    final rows = _buildNodes(nodos, 0);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8.5),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.08),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(9),
              ),
              border: Border(
                bottom: BorderSide(color: accentColor.withValues(alpha: 0.16)),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(icon, size: 15, color: accentColor),
                    const SizedBox(width: 6),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: accentColor,
                      ),
                    ),
                  ],
                ),
                Text(
                  FormatterNumber.formatCurrency(total),
                  style: TextStyle(
                    fontSize: 12.5,
                    fontFamily: 'Consolas',
                    fontWeight: FontWeight.w900,
                    color: accentColor,
                  ),
                ),
              ],
            ),
          ),
          if (rows.isEmpty && extraBottomRows.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Text(
                'Sin movimientos registrados en este rubro.',
                style: TextStyle(
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey.shade500,
                ),
              ),
            )
          else ...[
            ...rows,
            ...extraBottomRows,
          ],
        ],
      ),
    );
  }
}

