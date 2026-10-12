import 'package:flutter/material.dart';

import '../../palletes/app_colors.dart';
import '../../utils/helpers.dart';
import '../models/mesa_model.dart';

class MesaCardWidget extends StatelessWidget {
  final MesaModel mesa;
  final VoidCallback onOpenComanda;
  final VoidCallback onEditar;
  final VoidCallback onLiberar;
  final VoidCallback onEliminar;
  final bool isAdmin;

  const MesaCardWidget({
    super.key,
    required this.mesa,
    required this.onOpenComanda,
    required this.onEditar,
    required this.onLiberar,
    required this.onEliminar,
    this.isAdmin = false,
  });

  Color _getStatusColor(String estado) {
    switch (estado) {
      case 'Libre':
        return Colors.green.shade700;
      case 'Ocupada':
        return Colors.orange.shade800;
      case 'PorCobrar':
        return Colors.blue.shade700;
      default:
        return Colors.grey.shade600;
    }
  }

  Color _getStatusBgColor(String estado) {
    switch (estado) {
      case 'Libre':
        return Colors.green.shade50;
      case 'Ocupada':
        return Colors.orange.shade50;
      case 'PorCobrar':
        return Colors.blue.shade50;
      default:
        return Colors.grey.shade100;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(mesa.estado);
    final statusBgColor = _getStatusBgColor(mesa.estado);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: mesa.isLibre
              ? const Color(0xFFE5E7EB)
              : statusColor.withValues(alpha: 0.6),
          width: mesa.isLibre ? 1.0 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Nombre y Menú contextual
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 4, 2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    mesa.nombre.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: AppColors.secondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isAdmin)
                  PopupMenuButton<String>(
                    tooltip: 'Opciones de mesa',
                    icon: const Icon(
                      Icons.more_vert,
                      size: 16,
                      color: Colors.grey,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onSelected: (val) {
                      if (val == 'editar') onEditar();
                      if (val == 'eliminar') onEliminar();
                      if (val == 'liberar') onLiberar();
                    },
                    itemBuilder: (ctx) => [
                      const PopupMenuItem(
                        value: 'editar',
                        child: Text('Editar Mesa', style: TextStyle(fontSize: 12)),
                      ),
                      if (!mesa.isLibre)
                        const PopupMenuItem(
                          value: 'liberar',
                          child: Text(
                            'Liberar Mesa',
                            style: TextStyle(fontSize: 12, color: Colors.red),
                          ),
                        ),
                      if (mesa.isLibre)
                        const PopupMenuItem(
                          value: 'eliminar',
                          child: Text(
                            'Eliminar Mesa',
                            style: TextStyle(fontSize: 12, color: Colors.red),
                          ),
                        ),
                    ],
                  ),
              ],
            ),
          ),

          // Área y Capacidad
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              children: [
                Icon(
                  Icons.place_outlined,
                  size: 11,
                  color: Colors.grey.shade500,
                ),
                const SizedBox(width: 3),
                Text(
                  mesa.area,
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                ),
                const Spacer(),
                Icon(
                  Icons.people_outline,
                  size: 11,
                  color: Colors.grey.shade500,
                ),
                const SizedBox(width: 3),
                Text(
                  '${mesa.capacidad}',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),

          const Spacer(),

          // Estado o Consumo
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: mesa.isLibre
                ? Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: statusBgColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'LIBRE',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: statusColor,
                      ),
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: statusBgColor,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              mesa.estado.toUpperCase(),
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: statusColor,
                              ),
                            ),
                          ),
                          Text(
                            '${mesa.ordenActiva?.detalles.length ?? 0} ítems',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        FormatterNumber.formatCurrency(mesa.totalConsumo),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
          ),

          const SizedBox(height: 8),

          // Botón inferior de acción rápida
          InkWell(
            onTap: onOpenComanda,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 7),
              decoration: BoxDecoration(
                color: mesa.isLibre ? AppColors.secondary : statusColor,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(9),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    mesa.isLibre ? Icons.add : Icons.restaurant_menu,
                    size: 13,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    mesa.isLibre ? 'Abrir Mesa' : 'Ver Comanda',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
