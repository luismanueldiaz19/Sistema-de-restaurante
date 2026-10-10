import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../palletes/app_colors.dart';
import '../../models/pago_compra.dart';
import '../../providers/cxp_provider.dart';
import '../../../utils/helpers.dart';
import '../../../facturacion/providers/metodo_pago_provider.dart';

class PagosCompraDialog extends ConsumerStatefulWidget {
  final int compraId;
  final double totalCompra;

  const PagosCompraDialog({
    super.key,
    required this.compraId,
    required this.totalCompra,
  });

  @override
  ConsumerState<PagosCompraDialog> createState() => _PagosCompraDialogState();
}

class _PagosCompraDialogState extends ConsumerState<PagosCompraDialog> {
  late Future<List<PagoCompra>> _future;

  @override
  void initState() {
    super.initState();
    _future = ref.read(cxpProvider.notifier).getPagosPorCompra(widget.compraId);
  }

  @override
  Widget build(BuildContext context) {
    final metodosState = ref.watch(metodoPagoProvider);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Colors.white,
      child: Container(
        width: 450,
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Historial de Pagos de la Factura',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.secondary,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.grey),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  splashRadius: 20,
                ),
              ],
            ),
            const Divider(height: 24),
            FutureBuilder<List<PagoCompra>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (snapshot.hasError) {
                  return const Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Center(
                      child: Text(
                        'Error al cargar los pagos',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  );
                }

                final pagos = snapshot.data ?? [];

                double totalPagado = 0;
                Map<String, double> pagosPorMetodo = {};

                for (var p in pagos) {
                  totalPagado += p.montoPagado;

                  String nombre =
                      p.metodoPagoId != null && metodosState.metodos.isNotEmpty
                      ? (metodosState.metodos
                            .firstWhere(
                              (m) => m.id == p.metodoPagoId,
                              orElse: () => metodosState.metodos.first,
                            )
                            .nombre)
                      : (p.metodoPago == 'N/A' ? 'Desconocido' : p.metodoPago);

                  pagosPorMetodo[nombre] =
                      (pagosPorMetodo[nombre] ?? 0.0) + p.montoPagado;
                }
                double balancePendiente = widget.totalCompra - totalPagado;
                if (balancePendiente < 0) balancePendiente = 0;

                return Column(
                  children: [
                    // Resumen
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Column(
                                children: [
                                  const Text(
                                    'Total Factura',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  Text(
                                    FormatterNumber.formatCurrency(
                                      widget.totalCompra,
                                    ),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                children: [
                                  const Text(
                                    'Total Pagado',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  Text(
                                    FormatterNumber.formatCurrency(totalPagado),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                children: [
                                  const Text(
                                    'Pendiente',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  Text(
                                    FormatterNumber.formatCurrency(
                                      balancePendiente,
                                    ),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: Colors.orange,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          if (pagosPorMetodo.isNotEmpty) ...[
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child: Divider(height: 1, color: Colors.black12),
                            ),
                            Wrap(
                              spacing: 24,
                              runSpacing: 12,

                              children: pagosPorMetodo.entries.map((e) {
                                return Column(
                                  children: [
                                    Text(
                                      e.key,
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    Text(
                                      FormatterNumber.formatCurrency(e.value),
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green,
                                      ),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (pagos.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(32.0),
                        child: Center(
                          child: Text(
                            'No hay pagos registrados para esta compra.',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      )
                    else
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 250),
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: pagos.length,
                          separatorBuilder: (_, __) =>
                              Divider(color: Colors.grey.shade100, height: 16),
                          itemBuilder: (context, index) {
                            final p = pagos[index];
                            return Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppColors.primary
                                                  .withValues(alpha: 0.1),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              '#${p.id}',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 10,
                                                color: AppColors.primary,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            p.fechaPago.split(' ')[0],
                                            style: TextStyle(
                                              color: Colors.grey.shade600,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Ref: ${p.referencia}',
                                        style: TextStyle(
                                          color: Colors.grey.shade700,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      FormatterNumber.formatCurrency(
                                        p.montoPagado,
                                      ),
                                      style: const TextStyle(
                                        color: Colors.green,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 14,
                                      ),
                                    ),
                                    Text(
                                      p.metodoPagoId != null &&
                                              metodosState.metodos.isNotEmpty
                                          ? (metodosState.metodos
                                                .firstWhere(
                                                  (m) => m.id == p.metodoPagoId,
                                                  orElse: () => metodosState
                                                      .metodos
                                                      .first,
                                                )
                                                .nombre)
                                          : (p.metodoPago == 'N/A'
                                                ? 'Desconocido'
                                                : p.metodoPago),
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
