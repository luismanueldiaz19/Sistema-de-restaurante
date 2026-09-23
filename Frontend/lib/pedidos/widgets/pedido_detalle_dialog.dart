import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../facturacion/providers/facturacion_provider.dart';
import '../../facturacion/screens/add_factura.dart';
import '../../facturacion/models/factura_item.dart';
import '../../facturacion/services/printer_ticket_pedido.dart';
import '../../modulo_producto/models/producto.dart';
import '../../palletes/app_colors.dart';
import '../../utils/helpers.dart';
import '../models/pedido.dart';
import '../providers/pedidos_provider.dart';

class PedidoDetalleDialog extends ConsumerWidget {
  final Pedido pedido;

  const PedidoDetalleDialog({super.key, required this.pedido});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 450,
        constraints: const BoxConstraints(maxHeight: 600),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '# ${pedido.secuenciaDiaria}',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Detalles del Pedido',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow(
                      Icons.person,
                      'Cliente:',
                      pedido.clienteNombre,
                    ),
                    _buildInfoRow(
                      Icons.phone,
                      'Teléfono:',
                      pedido.clienteTelefono,
                    ),
                    _buildInfoRow(
                      Icons.location_on,
                      'Dirección:',
                      pedido.direccion ?? 'N/A',
                    ),
                    _buildInfoRow(
                      Icons.delivery_dining,
                      'Entrega:',
                      pedido.tipoEntrega,
                    ),
                    _buildInfoRow(Icons.info, 'Estado:', pedido.estado),
                    if (pedido.nota != null && pedido.nota!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.yellow.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.note, color: Colors.orange, size: 16),
                            const SizedBox(width: 8),
                            Expanded(child: Text('Nota: ${pedido.nota}', style: const TextStyle(fontSize: 13))),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    const Text(
                      'Artículos',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Divider(),
                    ...pedido.detalles
                        .map(
                          (det) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Row(
                              children: [
                                Text(
                                  '${det.cantidad}x',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(child: Text(det.nombreProducto, style: const TextStyle(fontSize: 13))),
                                Text(formatCurrency(det.subtotal), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        const Text(
                          'Total:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          formatCurrency(pedido.total),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(20),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: _buildActions(context, ref),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey, size: 16),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildActions(BuildContext context, WidgetRef ref) {
    final provider = ref.read(pedidosProvider);
    List<Widget> actions = [];

    // Botón Imprimir Pedido
    actions.add(
      ElevatedButton.icon(
        onPressed: () async {
          final isCopy = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text(
                'Imprimir Pedido',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              content: const Text(
                '¿Desea imprimir como documento original o como copia?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text(
                    'Original',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => Navigator.pop(ctx, true),
                  icon: const Icon(Icons.copy, size: 18),
                  label: const Text('Copia'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          );

          if (isCopy == null) return;

          final printer = PedidoPrinterService.instance;
          final result = await printer.imprimirPedido(pedido, esCopia: isCopy);

          if (context.mounted) {
            if (result.exito) {
              showToast(context, '🖨️ Ticket impreso', bgColor: Colors.green);
            } else {
              showToast(context, result.mensaje, bgColor: Colors.orange);
            }
          }
        },
        icon: const Icon(Icons.print, size: 18),
        label: const Text('Imprimir'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.grey.shade700,
          foregroundColor: Colors.white,
        ),
      ),
    );

    actions.add(const SizedBox(width: 12));

    if (pedido.estado == 'Pendiente') {
      actions.add(
        OutlinedButton(
          onPressed: () async {
            await provider.updatePedidoStatus(pedido.id!, 'Cancelado');
            if (context.mounted) Navigator.pop(context);
          },
          style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
          child: const Text('Cancelar Pedido'),
        ),
      );
      actions.add(const SizedBox(width: 12));
      actions.add(
        ElevatedButton.icon(
          onPressed: () async {
            await provider.updatePedidoStatus(pedido.id!, 'Confirmado');
            if (context.mounted) Navigator.pop(context);
          },
          icon: const Icon(Icons.check),
          label: const Text('Confirmar & Preparar'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
        ),
      );
    } else if (pedido.estado == 'Confirmado' || pedido.estado == 'Preparando') {
      actions.add(
        ElevatedButton.icon(
          onPressed: () async {
            // Mandar a facturar
            final factProvider = ref.read(facturacionProvider.notifier);
            factProvider.limpiarCarrito();

            print("=== PEDIDO DETALLES LENGTH: ${pedido.detalles.length}");
            print("=== ANTES DE AGREGAR: ${factProvider.state.carrito.length}");

            for (var det in pedido.detalles) {
              final p = Producto(
                id: det.productoId ?? 0,
                codigo: det.productoId.toString(),
                nombre: det.nombreProducto,
                precioVenta: det.precioUnitario,
              );
              final item = FacturaItem(
                cantidad: det.cantidad,

                id: p.id.toString(),
                descripcion: p.nombre!,
                precio: p.precioVenta!,
              );
              factProvider.agregarProducto(item);
            }

            print(
              "=== DESPUES DE AGREGAR: ${factProvider.state.carrito.length}",
            );

            // Aquí marcamos el pedido como facturado
            await provider.updatePedidoStatus(pedido.id!, 'Facturado');

            if (context.mounted) {
              Navigator.pop(context); // cerrar popup
              // Navegar a Facturacion
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (ctx) => const CrearFacturaPage()),
              );
            }
          },
          icon: const Icon(Icons.receipt_long),
          label: const Text('Facturar'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
          ),
        ),
      );
    }

    if (actions.isEmpty) {
      actions.add(
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cerrar'),
        ),
      );
    }

    return actions;
  }
}
