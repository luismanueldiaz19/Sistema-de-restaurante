import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../palletes/app_colors.dart';
import '../../widgets/custom_text_field.dart';
import '../providers/cxp_provider.dart';
import '../models/cxp.dart';

class CxpListScreen extends ConsumerStatefulWidget {
  const CxpListScreen({super.key});

  @override
  ConsumerState<CxpListScreen> createState() => _CxpListScreenState();
}

class _CxpListScreenState extends ConsumerState<CxpListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(cxpProvider.notifier).loadCxps();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(cxpProvider);

    return Scaffold(
      backgroundColor: AppColors.light,
      appBar: AppBar(
        title: const Text(
          'Cuentas por Pagar (CxP)',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
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
          : _buildList(state.cxps),
    );
  }

  Widget _buildList(List<CuentaPorPagar> cxps) {
    final pendientes = cxps.where((c) => c.balancePendiente > 0).toList();

    if (pendientes.isEmpty) {
      return const Center(
        child: Text(
          'No hay cuentas por pagar pendientes.',
          style: TextStyle(fontSize: 18),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: pendientes.length,
      itemBuilder: (context, index) {
        final cxp = pendientes[index];
        final isVencida =
            cxp.fechaVencimiento.isBefore(DateTime.now()) &&
            cxp.balancePendiente > 0;

        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            side: BorderSide(
              color: isVencida ? Colors.red : Colors.transparent,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            title: Text(
              'Proveedor: ${cxp.proveedor?.nombre ?? 'N/A'}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Text('Factura: ${cxp.compra?.numeroFacturaProveedor ?? 'N/A'}'),
                Text(
                  'Vence: ${cxp.fechaVencimiento.toLocal().toString().split(' ')[0]}',
                  style: TextStyle(
                    color: isVencida ? Colors.red : Colors.black87,
                    fontWeight: isVencida ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value:
                      (cxp.montoOriginal - cxp.balancePendiente) /
                      cxp.montoOriginal,
                  backgroundColor: Colors.grey[300],
                  color: AppColors.primary,
                ),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text(
                  'Balance',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
                Text(
                  '\$${cxp.balancePendiente.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
            onTap: () => _showPagarModal(context, cxp),
          ),
        );
      },
    );
  }

  void _showPagarModal(BuildContext context, CuentaPorPagar cxp) {
    final montoCtrl = TextEditingController(
      text: cxp.balancePendiente.toStringAsFixed(2),
    );
    final refCtrl = TextEditingController();
    String metodo = 'EFECTIVO';
    // Dummy account for now, idealmente un dropdown de cajas/bancos del catalogo
    int cuentaOrigenId = 1;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              title: Text(
                'Abonar a Factura ${cxp.compra?.numeroFacturaProveedor}',
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Balance Pendiente: \$${cxp.balancePendiente.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: montoCtrl,
                      label: 'Monto a Pagar',
                      keyboardType: TextInputType.number,
                      prefixIcon: Icons.attach_money,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Método de Pago',
                        border: OutlineInputBorder(),
                      ),
                      value: metodo,
                      items: const [
                        DropdownMenuItem(
                          value: 'EFECTIVO',
                          child: Text('EFECTIVO'),
                        ),
                        DropdownMenuItem(
                          value: 'TRANSFERENCIA',
                          child: Text('TRANSFERENCIA'),
                        ),
                        DropdownMenuItem(
                          value: 'CHEQUE',
                          child: Text('CHEQUE'),
                        ),
                      ],
                      onChanged: (val) => setModalState(() => metodo = val!),
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: refCtrl,
                      label: 'Referencia (Opcional)',
                      prefixIcon: Icons.receipt,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                  ),
                  onPressed: () async {
                    final monto = double.tryParse(montoCtrl.text) ?? 0;
                    if (monto <= 0 || monto > cxp.balancePendiente) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Monto inválido')),
                      );
                      return;
                    }

                    final data = {
                      'monto_pagado': monto,
                      'fecha_pago': DateTime.now().toIso8601String().split('T')[0],
                      'metodo_pago': metodo,
                      'referencia': refCtrl.text,
                      'cuenta_origen_id': cuentaOrigenId,
                    };

                    final success = await ref
                        .read(cxpProvider.notifier)
                        .registrarPago(cxp.id, data);
                    if (success && context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Pago registrado con éxito'),
                        ),
                      );
                    }
                  },
                  child: const Text(
                    'Registrar Pago',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
