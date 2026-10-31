import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../model/catalogo_cuenta_model.dart';
import '../../palletes/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/configuracion_contable_provider.dart';
import '../../widgets/custom_filter_dropdown.dart';
import '../../widgets/custom_text_field.dart';

class CatalogoCuentaDialog extends ConsumerStatefulWidget {
  final CatalogoCuentaModel? cuenta;
  final CatalogoCuentaModel? cuentaPadreDefault;

  const CatalogoCuentaDialog({
    super.key,
    this.cuenta,
    this.cuentaPadreDefault,
  });

  @override
  ConsumerState<CatalogoCuentaDialog> createState() =>
      _CatalogoCuentaDialogState();
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

  static const List<String> _tiposBase = [
    'Activo',
    'Pasivo',
    'Capital',
    'Ingresos',
    'Costos',
    'Gastos',
  ];

  @override
  void initState() {
    super.initState();
    _codigoCtrl = TextEditingController(text: widget.cuenta?.codigo ?? '');
    _nombreCtrl = TextEditingController(text: widget.cuenta?.nombre ?? '');
    final initialNivel = widget.cuenta != null
        ? widget.cuenta!.nivel
        : (widget.cuentaPadreDefault != null
              ? widget.cuentaPadreDefault!.nivel + 1
              : 1);
    _nivelCtrl = TextEditingController(text: initialNivel.toString());
    _tipo = widget.cuenta?.tipo ?? widget.cuentaPadreDefault?.tipo ?? 'Activo';
    _padreId = widget.cuenta?.padreId ?? widget.cuentaPadreDefault?.id;
    _permiteMovimiento =
        widget.cuenta?.permiteMovimiento ?? (initialNivel >= 3);

    if (widget.cuenta == null && _padreId != null) {
      Future.microtask(() => _generarCodigoParaPadre(_padreId!));
    }
  }

  @override
  void dispose() {
    _codigoCtrl.dispose();
    _nombreCtrl.dispose();
    _nivelCtrl.dispose();
    super.dispose();
  }

  void _generarCodigoParaPadre(int padreId) {
    if (!mounted) return;
    final state = ref.read(configuracionContableProvider);
    final idx = state.catalogoCuentasCompleto.indexWhere(
      (c) => c.id == padreId,
    );
    if (idx < 0) return;

    final padre = state.catalogoCuentasCompleto[idx];
    final hijos = state.catalogoCuentasCompleto
        .where((c) => c.padreId == padreId)
        .toList();

    int maxSec = 0;
    final prefix = '${padre.codigo}.';
    for (final h in hijos) {
      if (h.codigo.startsWith(prefix)) {
        final suffix = h.codigo.substring(prefix.length).split('.').first;
        final n = int.tryParse(suffix) ?? 0;
        if (n > maxSec) maxSec = n;
      }
    }

    final next = maxSec + 1;
    final padLen = padre.nivel >= 2 ? 2 : 1;
    final nuevoNivel = padre.nivel + 1;

    setState(() {
      _codigoCtrl.text = '$prefix${next.toString().padLeft(padLen, '0')}';
      _nivelCtrl.text = nuevoNivel.toString();
      _tipo = padre.tipo;
      if (widget.cuenta == null && nuevoNivel >= 3) {
        _permiteMovimiento = true;
      }
    });
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    final token = ref.read(authProvider).token;
    if (token == null) return;

    setState(() => _isLoading = true);
    final payload = {
      'codigo': _codigoCtrl.text.trim(),
      'nombre': _nombreCtrl.text.trim().toUpperCase(),
      'tipo': _tipo,
      'nivel': int.tryParse(_nivelCtrl.text) ?? 1,
      'padre_id': _padreId,
      'permite_movimiento': _permiteMovimiento,
    };

    try {
      final notifier = ref.read(configuracionContableProvider.notifier);
      if (widget.cuenta == null) {
        await notifier.crearCuenta(token, payload);
      } else {
        await notifier.actualizarCuenta(token, widget.cuenta!.id, payload);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e', style: const TextStyle(fontSize: 12)),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(configuracionContableProvider);
    final cuentasPadre = state.catalogoCuentasCompleto
        .where((c) => c.id != widget.cuenta?.id)
        .toList();
    final tiposDisponibles = {..._tiposBase, _tipo}.toList();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.account_tree_outlined,
                      size: 18,
                      color: AppColors.azulOscuro,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.cuenta == null
                            ? (widget.cuentaPadreDefault != null
                                  ? 'Nueva Subcuenta de ${widget.cuentaPadreDefault!.codigo}'
                                  : 'Nueva Cuenta Raíz')
                            : 'Editar Cuenta ${widget.cuenta!.codigo}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.azulOscuro,
                        ),
                      ),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'Cuenta Padre (Opcional)',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 4),
                SizedBox(
                  width: double.infinity,
                  child: CustomFilterDropdown<int?>(
                    height: 36,
                    isExpanded: true,
                    value: cuentasPadre.any((c) => c.id == _padreId)
                        ? _padreId
                        : null,
                    items: [
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text('Ninguna (Cuenta de Nivel Raíz)'),
                      ),
                      ...cuentasPadre.map(
                        (c) => DropdownMenuItem<int?>(
                          value: c.id,
                          child: Text(
                            '${c.codigo} - ${c.nombre}',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                    onChanged: (v) {
                      setState(() {
                        _padreId = v;
                        if (v == null) _nivelCtrl.text = '1';
                      });
                      if (v != null) _generarCodigoParaPadre(v);
                    },
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: CustomTextField(
                        controller: _codigoCtrl,
                        label: 'Código Contable',
                        hintText: 'Ej. 1.1.01.04',
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tipo de Cuenta',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          SizedBox(
                            width: double.infinity,
                            child: CustomFilterDropdown<String>(
                              height: 36,
                              value: _tipo,
                              items: tiposDisponibles
                                  .map(
                                    (t) => DropdownMenuItem(
                                      value: t,
                                      child: Text(t),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) {
                                if (v != null) setState(() => _tipo = v);
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: CustomTextField(
                        controller: _nivelCtrl,
                        label: 'Nivel',
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        validator: (v) =>
                            (v == null || v.isEmpty) ? 'Req.' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                CustomTextField(
                  controller: _nombreCtrl,
                  label: 'Nombre de la Cuenta',
                  hintText: 'Ej. CAJA GENERAL PRINCIPAL',
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                ),
                const SizedBox(height: 6),
                SwitchListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                  activeThumbColor: AppColors.primary,
                  title: const Text(
                    'Permite movimientos (Cuenta Transaccional)',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    'Actívalo solo en cuentas detalle que reciben asientos.',
                    style: TextStyle(fontSize: 10.5, color: Colors.grey.shade600),
                  ),
                  value: _permiteMovimiento,
                  onChanged: (v) => setState(() => _permiteMovimiento = v),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isLoading
                          ? null
                          : () => Navigator.pop(context),
                      child: const Text(
                        'Cancelar',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _guardar,
                      icon: const Icon(Icons.save_rounded, size: 15),
                      label: const Text(
                        'Guardar Cuenta',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.azulOscuro,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
