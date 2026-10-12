import 'package:flutter/material.dart';

import '../../modulo_mesas/models/mesa_model.dart';
import '../../palletes/app_colors.dart';
import '../../utils/helpers.dart';

class SeleccionarMesaDialog extends StatelessWidget {
  final List<MesaModel> mesas;

  const SeleccionarMesaDialog({super.key, required this.mesas});

  @override
  Widget build(BuildContext context) {
    final mesasConConsumo = mesas
        .where((m) => m.ordenActiva != null && m.ordenActiva!.detalles.isNotEmpty)
        .toList();

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      titlePadding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      actionsPadding: const EdgeInsets.all(10),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.deepOrange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(
              Icons.table_restaurant_rounded,
              color: Colors.deepOrange,
              size: 18,
            ),
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Cargar Comanda de Mesa',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.secondary,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18, color: Colors.grey),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      content: SizedBox(
        width: 440,
        height: 320,
        child: mesasConConsumo.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.table_restaurant_outlined,
                      size: 40,
                      color: Colors.grey.shade300,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'No hay mesas con cuentas abiertas',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Todas las mesas se encuentran libres o sin consumos activos.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                    ),
                  ],
                ),
              )
            : ListView.separated(
                itemCount: mesasConConsumo.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (ctx, i) {
                  final mesa = mesasConConsumo[i];
                  final itemsCount = mesa.ordenActiva?.detalles.length ?? 0;
                  final total = mesa.totalConsumo;

                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    leading: Container(
                      width: 40,
                      height: 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: mesa.isPorCobrar
                            ? Colors.blue.shade50
                            : Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: mesa.isPorCobrar
                              ? Colors.blue.shade300
                              : Colors.orange.shade300,
                        ),
                      ),
                      child: Text(
                        mesa.nombre,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: mesa.isPorCobrar
                              ? Colors.blue.shade800
                              : Colors.orange.shade800,
                        ),
                      ),
                    ),
                    title: Text(
                      'Mesa ${mesa.nombre} • ${mesa.area}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      '$itemsCount platos/bebidas • ${mesa.estado}',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          FormatterNumber.formatCurrency(total),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color: AppColors.primary,
                          ),
                        ),
                        const Text(
                          'Cargar a Caja',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                    onTap: () => Navigator.pop(context, mesa),
                  );
                },
              ),
      ),
    );
  }
}
