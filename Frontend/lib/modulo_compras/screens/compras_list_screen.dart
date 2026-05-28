import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../palletes/app_colors.dart';
import '../providers/compras_provider.dart';
import 'nueva_compra_screen.dart';

class ComprasListScreen extends ConsumerStatefulWidget {
  const ComprasListScreen({super.key});

  @override
  ConsumerState<ComprasListScreen> createState() => _ComprasListScreenState();
}

class _ComprasListScreenState extends ConsumerState<ComprasListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(comprasProvider.notifier).loadCompras();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(comprasProvider);

    return Scaffold(
      backgroundColor: AppColors.light,
      appBar: AppBar(
        title: const Text('Historial de Compras', style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Nueva Compra',
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const NuevaCompraScreen()));
            },
          ),
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.error != null
              ? Center(
                  child: Text(
                    'Error: ${state.error}',
                    style: TextStyle(color: AppColors.danger),
                  ),
                )
              : _buildList(state),
    );
  }

  Widget _buildList(ComprasState state) {
    if (state.compras.isEmpty) {
      return const Center(child: Text('No hay compras registradas.', style: TextStyle(fontSize: 18)));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: state.compras.length,
      itemBuilder: (context, index) {
        final compra = state.compras[index];
        final isContado = compra.tipoCompra == 'CONTADO';
        
        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          child: ExpansionTile(
            leading: CircleAvatar(
              backgroundColor: isContado ? Colors.green : Colors.orange,
              child: Icon(isContado ? Icons.money : Icons.credit_card, color: Colors.white),
            ),
            title: Text('Factura: ${compra.numeroFacturaProveedor}', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('Proveedor: ${compra.proveedor?.nombre ?? 'N/A'} | Fecha: ${compra.fechaCompra.toLocal().toString().split(' ')[0]}'),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('\$${compra.total.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text(compra.estado, style: TextStyle(color: compra.estado == 'PAGADA' ? Colors.green : Colors.red, fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
            children: [
              Container(
                color: Colors.grey[50],
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('Detalles de la compra', style: TextStyle(fontWeight: FontWeight.bold)),
                    const Divider(),
                    ...compra.detalles.map((d) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('${d.cantidad}x ${d.producto?.nombre ?? d.descripcion}'),
                          Text('\$${d.total.toStringAsFixed(2)}'),
                        ],
                      ),
                    )),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total:', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text('\$${compra.total.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              )
            ],
          ),
        );
      },
    );
  }
}
