import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../palletes/app_colors.dart';
import '../models/metodo_pago.dart';
import '../providers/metodo_pago_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/configuracion_contable_provider.dart';

class MetodosPagoScreen extends ConsumerStatefulWidget {
  const MetodosPagoScreen({super.key});

  @override
  ConsumerState<MetodosPagoScreen> createState() => _MetodosPagoScreenState();
}

class _MetodosPagoScreenState extends ConsumerState<MetodosPagoScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(metodoPagoProvider).fetchTodos();
      final token = ref.read(authProvider).token;
      if (token != null) {
        ref.read(configuracionContableProvider.notifier).loadAllData(token);
      }
    });
  }

  void _abrirDialogoMetodo([MetodoPago? metodo]) {
    showDialog(
      context: context,
      builder: (ctx) => _MetodoPagoDialog(metodo: metodo),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(metodoPagoProvider);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Métodos de Pago'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.error.isNotEmpty
          ? Center(child: Text('Error: ${state.error}'))
          : ListView.builder(
              padding: const EdgeInsets.all(24),
              itemCount: state.metodos.length,
              itemBuilder: (context, index) {
                final m = state.metodos[index];
                return Card(
                  elevation: 0,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: Colors.grey.shade200),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    leading: CircleAvatar(
                      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                      child: Icon(
                        m.tipo == 'tarjeta'
                            ? Icons.credit_card
                            : m.tipo == 'transferencia'
                            ? Icons.account_balance
                            : Icons.payments,
                        color: AppColors.primary,
                      ),
                    ),
                    title: Text(
                      m.nombre,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      'Tipo: ${m.tipo.toUpperCase()} \nCuenta Contable: ${m.cuentaContable?['nombre'] ?? 'Ninguna'}',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        height: 1.5,
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Switch(
                          value: m.activo,
                          activeColor: AppColors.primary,
                          onChanged: (val) {
                            ref.read(metodoPagoProvider).actualizarMetodo(
                              m.id,
                              {'activo': val},
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.grey),
                          onPressed: () => _abrirDialogoMetodo(m),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _abrirDialogoMetodo(),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Nuevo Método',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}

class _MetodoPagoDialog extends ConsumerStatefulWidget {
  final MetodoPago? metodo;
  const _MetodoPagoDialog({this.metodo});

  @override
  ConsumerState<_MetodoPagoDialog> createState() => _MetodoPagoDialogState();
}

class _MetodoPagoDialogState extends ConsumerState<_MetodoPagoDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nombreCtrl;
  String _tipo = 'efectivo';
  int? _catalogoCuentaId;

  @override
  void initState() {
    super.initState();
    _nombreCtrl = TextEditingController(text: widget.metodo?.nombre ?? '');
    _tipo = widget.metodo?.tipo ?? 'efectivo';
    _catalogoCuentaId = widget.metodo?.catalogoCuentaId;
  }

  void _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    final data = {
      'nombre': _nombreCtrl.text,
      'tipo': _tipo,
      'catalogo_cuenta_id': _catalogoCuentaId,
      'activo': widget.metodo?.activo ?? true,
    };

    try {
      if (widget.metodo == null) {
        await ref.read(metodoPagoProvider).crearMetodo(data);
      } else {
        await ref
            .read(metodoPagoProvider)
            .actualizarMetodo(widget.metodo!.id, data);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cuentas = ref.watch(configuracionContableProvider).catalogoCuentas;
    final isEditing = widget.metodo != null;

    // Solo mostrar cuentas de control falso y de tipo activos o bancos (o todas las transaccionales)
    final cuentasTransaccionales = cuentas
        .where((c) => c.permiteMovimiento)
        .toList();

    return AlertDialog(
      title: Text(isEditing ? 'Editar Método' : 'Nuevo Método de Pago'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nombreCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nombre (Ej. Banco BHD)',
                ),
                validator: (v) => v!.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _tipo,
                decoration: const InputDecoration(labelText: 'Tipo'),
                items: const [
                  DropdownMenuItem(value: 'efectivo', child: Text('Efectivo')),
                  DropdownMenuItem(value: 'tarjeta', child: Text('Tarjeta')),
                  DropdownMenuItem(
                    value: 'transferencia',
                    child: Text('Transferencia'),
                  ),
                ],
                onChanged: (v) => setState(() => _tipo = v!),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                value: _catalogoCuentaId,
                decoration: const InputDecoration(
                  labelText: 'Cuenta Contable (Opcional)',
                ),
                isExpanded: true,
                items: [
                  const DropdownMenuItem<int>(
                    value: null,
                    child: Text('Ninguna'),
                  ),
                  ...cuentasTransaccionales.map(
                    (c) => DropdownMenuItem(
                      value: c.id,
                      child: Text('${c.codigo} - ${c.nombre}'),
                    ),
                  ),
                ],
                onChanged: (v) => setState(() => _catalogoCuentaId = v),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(onPressed: _guardar, child: const Text('Guardar')),
      ],
    );
  }
}
