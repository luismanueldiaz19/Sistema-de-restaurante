import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../palletes/app_colors.dart';
import '../../../../widgets/custom_text_field.dart';
import '../../../providers/configuracion_contable_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../providers/nueva_compra_form_provider.dart';

class GastoFormDetalle extends ConsumerStatefulWidget {
  const GastoFormDetalle({super.key});

  @override
  ConsumerState<GastoFormDetalle> createState() => _GastoFormDetalleState();
}

class _GastoFormDetalleState extends ConsumerState<GastoFormDetalle> {
  int? _selectedCuentaId;
  final TextEditingController _descripcionCtrl = TextEditingController();
  final TextEditingController _montoCtrl = TextEditingController();
  final TextEditingController _impuestoCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final token = ref.read(authProvider).token;
      if (token != null) {
        ref.read(configuracionContableProvider.notifier).loadAllData(token);
      }
    });
  }

  @override
  void dispose() {
    _descripcionCtrl.dispose();
    _montoCtrl.dispose();
    _impuestoCtrl.dispose();
    super.dispose();
  }

  void _agregarGasto() {
    if (_selectedCuentaId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Seleccione una cuenta contable'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final monto = double.tryParse(_montoCtrl.text) ?? 0;
    if (monto <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ingrese un monto válido'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final impuesto = double.tryParse(_impuestoCtrl.text) ?? 0;

    final configState = ref.read(configuracionContableProvider);
    final cuentasGastos = configState.catalogoCuentasCompleto
        .where(
          (c) =>
              (c.tipo.toUpperCase() == 'GASTOS' ||
                  c.tipo.toUpperCase() == 'COSTOS') &&
              c.permiteMovimiento,
        )
        .toList();
    final cuenta = cuentasGastos.firstWhere(
      (c) => c.id == _selectedCuentaId,
      orElse: () => cuentasGastos.first,
    );

    final detalle = NuevaCompraDetalleItem(
      cuentaContableId: _selectedCuentaId,
      descripcionGasto: _descripcionCtrl.text.isEmpty
          ? cuenta.nombre
          : _descripcionCtrl.text,
      cantidad: 1, // La cantidad siempre es 1 para un gasto genérico
      costoUnitario: monto,
      impuestoMonto: impuesto,
    );

    ref.read(nuevaCompraFormProvider.notifier).addDetalle(detalle);

    _descripcionCtrl.clear();
    _montoCtrl.clear();
    _impuestoCtrl.clear();
    setState(() {
      _selectedCuentaId = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final configState = ref.watch(configuracionContableProvider);

    if (configState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Filtrar cuentas de Gastos que permitan movimientos
    final cuentasGastos = configState.catalogoCuentasCompleto
        .where(
          (c) =>
              (c.tipo.toUpperCase() == 'GASTOS' ||
                  c.tipo.toUpperCase() == 'COSTOS') &&
              c.permiteMovimiento,
        )
        .toList();

    return Container(
      margin: const EdgeInsets.only(top: 24, bottom: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Detalle del Gasto',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),

          // Selector de Cuenta
          const Text(
            'Cuenta Contable de Gasto',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF616161),
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<int>(
            value: _selectedCuentaId,
            isExpanded: true,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            ),
            items: cuentasGastos.map((c) {
              return DropdownMenuItem<int>(
                value: c.id,
                child: Text('${c.codigo} - ${c.nombre}', style: const TextStyle(fontSize: 14)),
              );
            }).toList(),
            onChanged: (val) {
              setState(() {
                _selectedCuentaId = val;
              });
            },
          ),
          const SizedBox(height: 16),

          // Descripción
          CustomTextField(
            controller: _descripcionCtrl,
            label: 'Descripción del Gasto (Opcional)',
            hintText: 'Ej. Pago de luz eléctrica agosto',
            prefixIcon: Icons.description_outlined,
          ),
          const SizedBox(height: 16),

          // Montos
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: CustomTextField(
                  controller: _montoCtrl,
                  label: 'Monto (Subtotal)',
                  prefixIcon: Icons.attach_money,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CustomTextField(
                  controller: _impuestoCtrl,
                  label: 'Impuestos (ITBIS)',
                  prefixIcon: Icons.receipt_long,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _agregarGasto,
              icon: const Icon(Icons.add_circle_outline, color: Colors.white),
              label: const Text(
                'Agregar Gasto al Detalle',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
    );
  }
}
