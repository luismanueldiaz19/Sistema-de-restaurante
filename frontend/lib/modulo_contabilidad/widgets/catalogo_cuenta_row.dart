import 'package:flutter/material.dart';
import '../../model/catalogo_cuenta_model.dart';
import '../../palletes/app_colors.dart';

class CatalogoCuentaRow extends StatelessWidget {
  final CatalogoCuentaModel cuenta;
  final int depth;
  final int totalHijosDirectos;
  final bool isExpanded;
  final VoidCallback? onToggleExpand;
  final VoidCallback onAddChild;
  final VoidCallback onEdit;
  final VoidCallback? onDelete;

  const CatalogoCuentaRow({
    super.key,
    required this.cuenta,
    required this.depth,
    required this.totalHijosDirectos,
    required this.isExpanded,
    this.onToggleExpand,
    required this.onAddChild,
    required this.onEdit,
    this.onDelete,
  });

  Color _tipoColor(String tipo) {
    switch (tipo.toLowerCase()) {
      case 'activo':
        return Colors.teal.shade700;
      case 'pasivo':
        return Colors.orange.shade800;
      case 'capital':
      case 'patrimonio':
        return Colors.deepPurple.shade700;
      case 'ingresos':
      case 'ingreso':
        return Colors.green.shade700;
      case 'costos':
      case 'costo':
        return Colors.brown.shade700;
      case 'gastos':
      case 'gasto':
        return Colors.red.shade700;
      default:
        return Colors.blueGrey.shade700;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tieneHijos = totalHijosDirectos > 0;
    final esRaiz = cuenta.nivel == 1;
    final tColor = _tipoColor(cuenta.tipo);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6.5),
      decoration: BoxDecoration(
        color: esRaiz ? const Color(0xFFF8FAFC) : Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          // Columna Jerárquica: Sangría + Chevron + Ícono + Código + Nombre
          Expanded(
            flex: 6,
            child: Padding(
              padding: EdgeInsets.only(left: depth * 18.0),
              child: Row(
                children: [
                  if (tieneHijos)
                    InkWell(
                      onTap: onToggleExpand,
                      borderRadius: BorderRadius.circular(4),
                      child: Padding(
                        padding: const EdgeInsets.all(2),
                        child: Icon(
                          isExpanded
                              ? Icons.keyboard_arrow_down_rounded
                              : Icons.keyboard_arrow_right_rounded,
                          size: 17,
                          color: AppColors.azulOscuro,
                        ),
                      ),
                    )
                  else
                    const SizedBox(width: 21),
                  Icon(
                    tieneHijos
                        ? (isExpanded
                              ? Icons.folder_open_rounded
                              : Icons.folder_rounded)
                        : Icons.description_outlined,
                    size: 16,
                    color: tieneHijos
                        ? AppColors.primary
                        : Colors.blueGrey.shade500,
                  ),
                  const SizedBox(width: 7),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: esRaiz
                          ? AppColors.azulOscuro.withValues(alpha: 0.09)
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      cuenta.codigo,
                      style: TextStyle(
                        fontFamily: 'Consolas',
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppColors.azulOscuro,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      cuenta.nombre,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: esRaiz ? 12.5 : 12,
                        fontWeight: tieneHijos
                            ? FontWeight.w800
                            : FontWeight.w600,
                        color: AppColors.azulOscuro,
                      ),
                    ),
                  ),
                  if (tieneHijos && !isExpanded) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$totalHijosDirectos',
                        style: const TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Tipo de Cuenta
          SizedBox(
            width: 88,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: tColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  cuenta.tipo,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: tColor,
                  ),
                ),
              ),
            ),
          ),

          // Nivel
          SizedBox(
            width: 62,
            child: Text(
              'Niv. ${cuenta.nivel}',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
          ),

          // Naturaleza / Movimiento
          SizedBox(
            width: 112,
            child: Align(
              alignment: Alignment.center,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: cuenta.permiteMovimiento
                      ? Colors.green.shade50
                      : Colors.blueGrey.shade50,
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(
                    color: cuenta.permiteMovimiento
                        ? Colors.green.shade200
                        : Colors.blueGrey.shade200,
                  ),
                ),
                child: Text(
                  cuenta.permiteMovimiento ? 'Transaccional' : 'Grupo / Padre',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: cuenta.permiteMovimiento
                        ? Colors.green.shade800
                        : Colors.blueGrey.shade700,
                  ),
                ),
              ),
            ),
          ),

          // Acciones
          SizedBox(
            width: 96,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                  tooltip: 'Agregar subcuenta dentro de ${cuenta.codigo}',
                  icon: Icon(
                    Icons.add_circle_outline_rounded,
                    size: 16,
                    color: Colors.teal.shade700,
                  ),
                  onPressed: onAddChild,
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                  tooltip: 'Editar cuenta',
                  icon: Icon(
                    Icons.edit_outlined,
                    size: 16,
                    color: Colors.blue.shade700,
                  ),
                  onPressed: onEdit,
                ),
                if (onDelete != null)
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 28,
                      minHeight: 28,
                    ),
                    tooltip: 'Eliminar cuenta',
                    icon: Icon(
                      Icons.delete_outline_rounded,
                      size: 16,
                      color: Colors.red.shade600,
                    ),
                    onPressed: onDelete,
                  )
                else
                  const SizedBox(width: 28),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

