import 'package:flutter/material.dart';
import '../../palletes/app_colors.dart';
import '../../utils/helpers.dart';

class CierreCajaListCard extends StatelessWidget {
  final Map<String, dynamic> session;
  final bool isSelected;
  final VoidCallback onTap;

  const CierreCajaListCard({
    super.key,
    required this.session,
    required this.isSelected,
    required this.onTap,
  });

  Color _getStatusColor() {
    final estado = session['estado']?.toString().toLowerCase();
    if (estado == 'abierta') {
      return Colors.green;
    }
    final diff = double.tryParse((session['diferencia'] ?? 0).toString()) ?? 0;
    if (diff == 0) {
      return AppColors.azulOscuro;
    } else if (diff > 0) {
      return Colors.blue.shade700;
    } else {
      return Colors.red.shade600;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor();
    final bool isAbierta = session['estado'] == 'abierta';
    final double diff =
        double.tryParse((session['diferencia'] ?? 0).toString()) ?? 0;
    final cajaNombre = session['caja']?['nombre'] ?? 'Caja';
    final turnoNombre = session['turno']?['nombre'] ?? 'Turno';
    final cajeroNombre = session['usuario']?['name'] ?? 'N/A';
    final fechaAperturaStr = session['fecha_apertura'] != null
        ? FormatterNumber.formatFechaHora(
            DateTime.parse(session['fecha_apertura']),
          )
        : 'N/A';

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: isSelected
              ? statusColor.withValues(alpha: 0.06)
              : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? statusColor : Colors.grey.shade200,
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: IntrinsicHeight(
            child: Row(
              children: [
                // Barra lateral de color según estado
                Container(width: 5, color: statusColor),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        // Avatar identificador con ID de sesión
                        CircleAvatar(
                          backgroundColor: statusColor.withValues(alpha: 0.12),
                          radius: 18,
                          child: Text(
                            "#${session['id']}",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: statusColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Información principal de la sesión
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      "$cajaNombre • $turnoNombre",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                        color: AppColors.azulOscuro,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isAbierta
                                          ? Colors.green.shade50
                                          : Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: isAbierta
                                            ? Colors.green.shade200
                                            : Colors.grey.shade300,
                                      ),
                                    ),
                                    child: Text(
                                      isAbierta ? "ABIERTA" : "CERRADA",
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        color: isAbierta
                                            ? Colors.green.shade800
                                            : Colors.grey.shade700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Row(
                                children: [
                                  Icon(
                                    Icons.access_time_rounded,
                                    size: 13,
                                    color: Colors.grey.shade500,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      fechaAperturaStr,
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey.shade600,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Icon(
                                    isAbierta
                                        ? Icons.radio_button_checked
                                        : Icons.account_balance_wallet_outlined,
                                    size: 13,
                                    color: isAbierta
                                        ? Colors.green
                                        : (diff == 0
                                              ? Colors.green
                                              : (diff > 0
                                                    ? Colors.blue
                                                    : Colors.red)),
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      isAbierta
                                          ? "Sesión activa en curso"
                                          : "Dif: ${FormatterNumber.formatCurrency(diff)}",
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: isAbierta
                                            ? Colors.green.shade700
                                            : (diff == 0
                                                  ? Colors.green.shade700
                                                  : (diff > 0
                                                        ? Colors.blue.shade700
                                                        : Colors.red.shade700)),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Icon(
                                    Icons.person_outline,
                                    size: 13,
                                    color: Colors.grey.shade400,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      cajeroNombre,
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey.shade500,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
