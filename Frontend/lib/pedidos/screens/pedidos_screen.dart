import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../palletes/app_colors.dart';
import '../../utils/helpers.dart';
import '../models/pedido.dart';
import '../providers/pedidos_provider.dart';
import '../widgets/pedido_detalle_dialog.dart';
import 'add_pedido.dart';

class PedidosScreen extends ConsumerStatefulWidget {
  const PedidosScreen({super.key});

  @override
  ConsumerState<PedidosScreen> createState() => _PedidosScreenState();
}

class _PedidosScreenState extends ConsumerState<PedidosScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(pedidosProvider).initPolling();
    });
  }

  @override
  void dispose() {
    // We let the provider handle its own dispose, but we can stop polling if desired.
    // Provider might be global, so we don't stop it if we want notifications, but for now we'll stop it when leaving screen.
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.blanco,
      appBar: AppBar(
        title: const Text(
          'Gestión de Pedidos',
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(pedidosProvider).fetchPedidos();
            },
          ),
          IconButton(
            icon: const Icon(Icons.calendar_month),
            onPressed: () async {
              final provider = ref.read(pedidosProvider);
              final date = await showDatePicker(
                context: context,
                initialDate: provider.currentDate,
                firstDate: DateTime(2020),
                lastDate: DateTime(2030),
              );
              if (date != null) {
                provider.changeDate(date);
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.add, size: 22),
            tooltip: 'Crear Pedido',
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CrearPedidoPage(),
                ),
              );
              if (result == true) {
                ref.read(pedidosProvider).fetchPedidos();
              }
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Consumer(
        builder: (context, ref, child) {
          final provider = ref.watch(pedidosProvider);
          if (provider.isLoading && provider.pedidos.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.error.isNotEmpty && provider.pedidos.isEmpty) {
            return Center(child: Text('Error: ${provider.error}'));
          }
          if (provider.pedidos.isEmpty) {
            return const Center(
              child: Text(
                'No hay pedidos para esta fecha',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildColumn(
                context,
                'Pendientes',
                provider.pedidos.where((p) => p.estado == 'Pendiente').toList(),
                Colors.orange,
              ),
              _buildColumn(
                context,
                'Preparando',
                provider.pedidos
                    .where(
                      (p) =>
                          p.estado == 'Confirmado' || p.estado == 'Preparando',
                    )
                    .toList(),
                Colors.blue,
              ),
              _buildColumn(
                context,
                'Completados',
                provider.pedidos.where((p) => p.estado == 'Facturado').toList(),
                Colors.green,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildColumn(
    BuildContext context,
    String title,
    List<Pedido> pedidos,
    Color color,
  ) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.05),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                border: Border(bottom: BorderSide(color: color.withValues(alpha: 0.1))),
              ),
              child: Row(
                children: [
                  Icon(Icons.list_alt, color: color, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${pedidos.length}',
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(6),
                itemCount: pedidos.length,
                itemBuilder: (context, index) {
                  final pedido = pedidos[index];
                  return _buildPedidoCard(context, pedido, color);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPedidoCard(
    BuildContext context,
    Pedido pedido,
    Color statusColor,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: () {
          showDialog(
            context: context,
            builder: (ctx) => PedidoDetalleDialog(pedido: pedido),
          );
        },
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '# ${pedido.secuenciaDiaria}',
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Text(
                    formatCurrency(pedido.total),
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.person, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      pedido.clienteNombre,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(
                    Icons.delivery_dining,
                    size: 14,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 4),
                  Text(pedido.tipoEntrega, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  const Spacer(),
                  Text(
                    '${pedido.detalles.length} art.',
                    style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
