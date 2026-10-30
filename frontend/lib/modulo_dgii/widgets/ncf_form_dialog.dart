import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../palletes/app_colors.dart';
import '../../utils/formatter_number.dart';
import '../../widgets/custom_filter_dropdown.dart';
import '../../widgets/custom_text_field.dart';
import '../models/ncf_secuencia_model.dart';
import '../providers/ncf_provider.dart';

class NcfFormDialog extends ConsumerStatefulWidget {
  final NcfSecuenciaModel? secuencia;

  const NcfFormDialog({super.key, this.secuencia});

  @override
  ConsumerState<NcfFormDialog> createState() => _NcfFormDialogState();
}

class _NcfFormDialogState extends ConsumerState<NcfFormDialog> {
  late String _prefijo;
  late TextEditingController _tipoCtrl;
  late TextEditingController _nombreCtrl;
  late TextEditingController _inicioCtrl;
  late TextEditingController _finCtrl;
  late TextEditingController _actualCtrl;
  late bool _activo;

  @override
  void initState() {
    super.initState();
    final s = widget.secuencia;
    _prefijo = (s?.prefijo ?? 'E').toUpperCase();
    _tipoCtrl = TextEditingController(text: s?.tipo ?? '');
    _nombreCtrl = TextEditingController(text: s?.nombre ?? '');
    _inicioCtrl = TextEditingController(text: (s?.rangoInicio ?? 1).toString());
    _finCtrl = TextEditingController(text: (s?.rangoFin ?? 10000).toString());
    _actualCtrl = TextEditingController(text: (s?.actual ?? 0).toString());
    _activo = s?.activo ?? true;
  }

  @override
  void dispose() {
    _tipoCtrl.dispose();
    _nombreCtrl.dispose();
    _inicioCtrl.dispose();
    _finCtrl.dispose();
    _actualCtrl.dispose();
    super.dispose();
  }

  String _previewProximo() {
    final tipo = _tipoCtrl.text.trim().isEmpty ? '32' : _tipoCtrl.text.trim();
    final ini = int.tryParse(_inicioCtrl.text) ?? 1;
    final fin = int.tryParse(_finCtrl.text) ?? 1;
    final act = int.tryParse(_actualCtrl.text) ?? 0;
    final next = math.max(act + 1, ini);
    if (next > fin) return 'AGOTADA (Próximo supera Rango Fin)';
    final pad = _prefijo == 'E' ? 10 : 8;
    final disp = FormatterNumber.formatNumber(((fin - next) + 1).toDouble());
    return '$_prefijo$tipo${next.toString().padLeft(pad, '0')}  •  $disp disponibles';
  }

  Future<void> _guardar() async {
    final ini = int.tryParse(_inicioCtrl.text) ?? 0;
    final fin = int.tryParse(_finCtrl.text) ?? 0;
    final act = int.tryParse(_actualCtrl.text) ?? -1;

    if (_tipoCtrl.text.trim().isEmpty || _nombreCtrl.text.trim().isEmpty) {
      _snack('Completa el código de tipo y el nombre del comprobante.');
      return;
    }
    if (ini < 1 || fin < ini || act < 0 || act > fin) {
      _snack('Verifica los rangos: Inicio >= 1, Fin >= Inicio y Actual <= Fin.');
      return;
    }

    final res = await ref.read(ncfProvider.notifier).guardarSecuencia(
      id: widget.secuencia?.id,
      payload: {
        'prefijo': _prefijo,
        'tipo': _tipoCtrl.text.trim(),
        'nombre': _nombreCtrl.text.trim(),
        'rango_inicio': ini,
        'rango_fin': fin,
        'actual': act,
        'activo': _activo,
      },
    );

    if (!mounted) return;
    _snack(res['message']?.toString() ?? '', ok: res['success'] == true);
    if (res['success'] == true) Navigator.pop(context);
  }

  void _snack(String msg, {bool ok = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontSize: 12)),
        backgroundColor: ok ? Colors.teal.shade700 : Colors.red.shade700,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final saving = ref.watch(ncfProvider).isSaving;
    final isEdit = widget.secuencia != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 490),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.confirmation_number_outlined,
                    size: 18,
                    color: AppColors.azulOscuro,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isEdit
                          ? 'Configurar Rango ${widget.secuencia!.codigo}'
                          : 'Nueva Secuencia NCF / e-NCF',
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
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Serie Fiscal',
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
                            value: _prefijo,
                            items: const [
                              DropdownMenuItem(
                                value: 'E',
                                child: Text('Serie E (Electrónico e-CF)'),
                              ),
                              DropdownMenuItem(
                                value: 'B',
                                child: Text('Serie B (NCF Tradicional)'),
                              ),
                            ],
                            onChanged: (v) {
                              if (v != null) setState(() => _prefijo = v);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: CustomTextField(
                      controller: _tipoCtrl,
                      label: 'Tipo (ej. 31, 32, 01)',
                      hintText: '32',
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              CustomTextField(
                controller: _nombreCtrl,
                label: 'Nombre del Comprobante',
                hintText: 'Ej. Factura de Consumo Electrónica',
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: _inicioCtrl,
                      label: 'Rango Inicio DGII',
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: CustomTextField(
                      controller: _finCtrl,
                      label: 'Rango Fin DGII',
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: CustomTextField(
                      controller: _actualCtrl,
                      label: 'Último Usado',
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.indigo.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.indigo.shade100),
                ),
                child: Text(
                  'Próximo a emitir: ${_previewProximo()}',
                  style: TextStyle(
                    fontFamily: 'Consolas',
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo.shade900,
                  ),
                ),
              ),
              SwitchListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
                activeThumbColor: AppColors.primary,
                title: const Text(
                  'Secuencia activa para facturación',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
                value: _activo,
                onChanged: (v) => setState(() => _activo = v),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancelar', style: TextStyle(fontSize: 12)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: saving ? null : _guardar,
                    icon: const Icon(Icons.save_rounded, size: 15),
                    label: const Text(
                      'Guardar Secuencia',
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
    );
  }
}

