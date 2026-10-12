import 'package:flutter/material.dart';

import '../../palletes/app_colors.dart';
import '../../utils/helpers.dart';
import '../models/mesa_model.dart';

class MesaComandaActions extends StatelessWidget {
  final MesaModel mesa;
  final double totalGeneral;
  final bool hasNuevosItems;
  final bool isSaving;
  final VoidCallback onEnviarCocina;
  final VoidCallback onImprimirPrecuenta;
  final VoidCallback onLiberar;
  final bool isAdmin;

  const MesaComandaActions({
    super.key,
    required this.mesa,
    required this.totalGeneral,
    required this.hasNuevosItems,
    required this.isSaving,
    required this.onEnviarCocina,
    required this.onImprimirPrecuenta,
    required this.onLiberar,
    this.isAdmin = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFEEEEEE))),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Total de la comanda
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            color: const Color(0xFFFAFAFA),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'TOTAL MESA:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.secondary,
                  ),
                ),
                Text(
                  FormatterNumber.formatCurrency(totalGeneral),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),

          // Botonera de acciones
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              children: [
                // Botón Enviar a Cocina / Abrir Mesa
                if (mesa.isLibre || hasNuevosItems) ...[
                  SizedBox(
                    width: double.infinity,
                    height: 38,
                    child: ElevatedButton.icon(
                      onPressed: (!hasNuevosItems || isSaving)
                          ? null
                          : onEnviarCocina,
                      icon: isSaving
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.outdoor_grill, size: 16),
                      label: Text(
                        mesa.isLibre
                            ? (hasNuevosItems
                                  ? 'Abrir Mesa y Enviar Comanda'
                                  : 'Selecciona platos para abrir mesa')
                            : 'Enviar Ronda a Cocina',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: hasNuevosItems
                            ? Colors.blue.shade700
                            : Colors.grey.shade300,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],

                // Botones cuando la mesa está ocupada
                if (!mesa.isLibre && mesa.ordenActiva != null) ...[
                  SizedBox(
                    width: double.infinity,
                    height: 38,
                    child: OutlinedButton.icon(
                      onPressed: onImprimirPrecuenta,
                      icon: const Icon(Icons.print, size: 15),
                      label: const Text(
                        'Imprimir Pre-cuenta',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey.shade800,
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Liberar mesa sin facturar (Solo Administrador)
                  if (isAdmin) ...[
                    TextButton.icon(
                      onPressed: onLiberar,
                      icon: const Icon(
                        Icons.meeting_room_outlined,
                        size: 13,
                        color: Colors.red,
                      ),
                      label: const Text(
                        'Liberar mesa sin facturar (Admin)',
                        style: TextStyle(fontSize: 11, color: Colors.red),
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
