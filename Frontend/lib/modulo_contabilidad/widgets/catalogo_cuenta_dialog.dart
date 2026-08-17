import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../model/catalogo_cuenta_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/configuracion_contable_provider.dart';

class CatalogoCuentaDialog extends ConsumerStatefulWidget {
  final CatalogoCuentaModel? cuenta;
  final CatalogoCuentaModel? cuentaPadreDefault;

  const CatalogoCuentaDialog({super.key, this.cuenta, this.cuentaPadreDefault});

  @override
  ConsumerState<CatalogoCuentaDialog> createState() => _CatalogoCuentaDialogState();
}

class _CatalogoCuentaDialogState extends ConsumerState<CatalogoCuentaDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _codigoCtrl;
  late TextEditingController _nombreCtrl;
  late TextEditingController _nivelCtrl;
  String _tipo = 'Activo';
  int? _padreId;
  bool _permiteMovimiento = false;
  bool _isLoading = false;

  final List<String> _tiposCuenta = [
    'Activo',
    'Pasivo',
    'Capital',
    'Ingresos',
    'Costos',
    'Gastos'
  ];

  @override
  void initState() {
    super.initState();
    _codigoCtrl = TextEditingController(text: widget.cuenta?.codigo ?? '');
    _nombreCtrl = TextEditingController(text: widget.cuenta?.nombre ?? '');
    _nivelCtrl = TextEditingController(
        text: widget.cuenta != null 
          ? widget.cuenta!.nivel.toString() 
          : (widget.cuentaPadreDefault != null ? (widget.cuentaPadreDefault!.nivel + 1).toString() : '1'));
    _tipo = widget.cuenta?.tipo ?? widget.cuentaPadreDefault?.tipo ?? 'Activo';
    _padreId = widget.cuenta?.padreId ?? widget.cuentaPadreDefault?.id;
    _permiteMovimiento = widget.cuenta?.permiteMovimiento ?? false;
  }

  void _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    final token = ref.read(authProvider).token;
    if (token == null) return;

    setState(() => _isLoading = true);

    final data = {
      'codigo': _codigoCtrl.text,
      'nombre': _nombreCtrl.text,
      'tipo': _tipo,
      'nivel': int.tryParse(_nivelCtrl.text) ?? 1,
      'padre_id': _padreId,
      'permite_movimiento': _permiteMovimiento,
    };

    try {
      if (widget.cuenta == null) {
        await ref.read(configuracionContableProvider.notifier).crearCuenta(token, data);
      } else {
        await ref.read(configuracionContableProvider.notifier).actualizarCuenta(token, widget.cuenta!.id, data);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(configuracionContableProvider);
    final cuentasPadre = state.catalogoCuentasCompleto.where((c) => c.id != widget.cuenta?.id).toList();

    return AlertDialog(
      title: Text(widget.cuenta == null ? 'Nueva Cuenta' : 'Editar Cuenta'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _codigoCtrl,
                decoration: const InputDecoration(labelText: 'Código (ej: 1.1.01)'),
                validator: (v) => v!.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nombreCtrl,
                decoration: const InputDecoration(labelText: 'Nombre'),
                validator: (v) => v!.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _tipo,
                decoration: const InputDecoration(labelText: 'Tipo de Cuenta'),
                items: _tiposCuenta.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                onChanged: (v) => setState(() => _tipo = v!),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nivelCtrl,
                decoration: const InputDecoration(labelText: 'Nivel'),
                keyboardType: TextInputType.number,
                validator: (v) => v!.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                value: _padreId,
                decoration: const InputDecoration(labelText: 'Cuenta Padre (Opcional)'),
                isExpanded: true,
                items: [
                  const DropdownMenuItem<int>(
                    value: null,
                    child: Text('Ninguna (Nivel Raíz)'),
                  ),
                  ...cuentasPadre.map((c) => DropdownMenuItem(
                    value: c.id,
                    child: Text('${c.codigo} - ${c.nombre}'),
                  ))
                ],
                onChanged: (v) => setState(() => _padreId = v),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Permite Movimiento (Transaccional)'),
                subtitle: const Text('Solo las cuentas detalle permiten transacciones'),
                value: _permiteMovimiento,
                onChanged: (v) => setState(() => _permiteMovimiento = v),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _guardar,
          child: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Guardar'),
        ),
      ],
    );
  }
}
