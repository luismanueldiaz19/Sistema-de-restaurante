import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../palletes/app_colors.dart';
import '../../utils/helpers.dart';
import '../providers/dgii_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/configuracion_contable_provider.dart';
import '../../model/catalogo_cuenta_model.dart';

class RegistrarPagoDgiiDialog extends ConsumerStatefulWidget {
  const RegistrarPagoDgiiDialog({super.key});

  @override
  ConsumerState<RegistrarPagoDgiiDialog> createState() => _RegistrarPagoDgiiDialogState();
}

class _RegistrarPagoDgiiDialogState extends ConsumerState<RegistrarPagoDgiiDialog> {
  final _montoCtrl = TextEditingController();
  final _refCtrl = TextEditingController();
  DateTime _fechaPago = DateTime.now();
  String _mes = DateTime.now().month.toString().padLeft(2, '0');
  String _anio = DateTime.now().year.toString();
  CatalogoCuentaModel? _cuentaSeleccionada;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final token = ref.read(authProvider).token;
      if (token != null) {
        ref.read(configuracionContableProvider.notifier).loadAllData(token);
      }
    });
  }

  void _submit() async {
    final monto = double.tryParse(_montoCtrl.text);
    if (monto == null || monto <= 0) {
      showToast(context, 'Monto inválido', bgColor: Colors.red);
      return;
    }
    if (_cuentaSeleccionada == null) {
      showToast(context, 'Debe seleccionar una cuenta origen', bgColor: Colors.red);
      return;
    }

    setState(() => _isSubmitting = true);

    final result = await ref.read(dgiiProvider.notifier).registrarPago(
      fechaPago: DateFormat('yyyy-MM-dd').format(_fechaPago),
      monto: monto,
      mes: _mes,
      anio: _anio,
      cuentaBancoId: _cuentaSeleccionada!.id,
      referencia: _refCtrl.text,
    );

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (result['success']) {
        showToast(context, 'Pago registrado con éxito', bgColor: Colors.green);
        Navigator.pop(context);
      } else {
        showToast(context, result['message'], bgColor: Colors.red);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final configState = ref.watch(configuracionContableProvider);
    
    // Filtrar cuentas de banco (ejemplo: cuentas que empiezan por 1.1.01 o que son de activo)
    // Para simplificar, mostramos todas o solo las que tienen permiteMovimiento = true
    final cuentasBanco = configState.catalogoCuentas.where((c) => c.codigo.startsWith('1.1.01') || c.codigo.startsWith('1.1.02')).toList();

    return AlertDialog(
      title: const Text('Registrar Pago a DGII', style: TextStyle(color: AppColors.secondary, fontWeight: FontWeight.bold)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Fecha Pago
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Fecha de Pago'),
                subtitle: Text(DateFormat('dd/MM/yyyy').format(_fechaPago)),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _fechaPago,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (date != null) setState(() => _fechaPago = date);
                },
              ),
              const SizedBox(height: 16),
              
              // Período
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _mes,
                      decoration: const InputDecoration(labelText: 'Mes'),
                      items: List.generate(12, (index) {
                        final val = (index + 1).toString().padLeft(2, '0');
                        return DropdownMenuItem(value: val, child: Text(val));
                      }),
                      onChanged: (val) => setState(() => _mes = val!),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _anio,
                      decoration: const InputDecoration(labelText: 'Año'),
                      items: List.generate(10, (index) {
                        final val = (DateTime.now().year - 5 + index).toString();
                        return DropdownMenuItem(value: val, child: Text(val));
                      }),
                      onChanged: (val) => setState(() => _anio = val!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Cuenta de Origen
              if (configState.isLoading)
                const CircularProgressIndicator()
              else
                DropdownButtonFormField<CatalogoCuentaModel>(
                  value: _cuentaSeleccionada,
                  decoration: const InputDecoration(labelText: 'Cuenta Bancaria de Origen'),
                  isExpanded: true,
                  items: cuentasBanco.map((cuenta) {
                    return DropdownMenuItem(
                      value: cuenta,
                      child: Text('${cuenta.codigo} - ${cuenta.nombre}'),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => _cuentaSeleccionada = val),
                ),
              const SizedBox(height: 16),

              // Monto a Pagar
              TextField(
                controller: _montoCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Monto a Pagar (RD\$)',
                  prefixIcon: Icon(Icons.attach_money),
                ),
              ),
              const SizedBox(height: 16),

              // Referencia
              TextField(
                controller: _refCtrl,
                decoration: const InputDecoration(
                  labelText: 'Referencia / No. Comprobante',
                  prefixIcon: Icon(Icons.receipt),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
          child: _isSubmitting
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('REGISTRAR PAGO'),
        ),
      ],
    );
  }
}
