import 'dart:io' as io;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../palletes/app_colors.dart';
import '../../widgets/custom_filter_dropdown.dart';
import '../../widgets/custom_text_field.dart';
import '../providers/ecf_provider.dart';

class EcfConfigCertDialog extends ConsumerStatefulWidget {
  const EcfConfigCertDialog({super.key});

  @override
  ConsumerState<EcfConfigCertDialog> createState() =>
      _EcfConfigCertDialogState();
}

class _EcfConfigCertDialogState extends ConsumerState<EcfConfigCertDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  late TextEditingController _rncCtrl;
  late TextEditingController _razonCtrl;
  late TextEditingController _comercialCtrl;
  late TextEditingController _dirCtrl;
  late TextEditingController _telCtrl;
  late TextEditingController _correoCtrl;
  final TextEditingController _p12PassCtrl = TextEditingController();

  String _ambiente = 'mock';
  bool _envioAuto = true;
  List<int>? _pickedBytes;
  String? _pickedName;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    final cfg = ref.read(ecfProvider).config;
    _ambiente = cfg.ambiente;
    _envioAuto = cfg.envioAutomatico;
    _rncCtrl = TextEditingController(text: cfg.rncEmisor);
    _razonCtrl = TextEditingController(text: cfg.razonSocial);
    _comercialCtrl = TextEditingController(text: cfg.nombreComercial);
    _dirCtrl = TextEditingController(text: cfg.direccion);
    _telCtrl = TextEditingController(text: cfg.telefono);
    _correoCtrl = TextEditingController(text: cfg.correo);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _rncCtrl.dispose();
    _razonCtrl.dispose();
    _comercialCtrl.dispose();
    _dirCtrl.dispose();
    _telCtrl.dispose();
    _correoCtrl.dispose();
    _p12PassCtrl.dispose();
    super.dispose();
  }

  void _notify(String msg, {bool ok = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontSize: 12)),
        backgroundColor: ok ? Colors.teal.shade700 : Colors.red.shade700,
      ),
    );
  }

  Future<void> _guardarConfig() async {
    final res = await ref.read(ecfProvider.notifier).guardarConfiguracion({
      'ambiente': _ambiente,
      'rnc_emisor': _rncCtrl.text.trim(),
      'razon_social': _razonCtrl.text.trim(),
      'nombre_comercial': _comercialCtrl.text.trim(),
      'direccion': _dirCtrl.text.trim(),
      'telefono': _telCtrl.text.trim(),
      'correo': _correoCtrl.text.trim().isEmpty ? null : _correoCtrl.text.trim(),
      'envio_automatico': _envioAuto,
    });
    _notify(res['message']?.toString() ?? '', ok: res['success'] == true);
    if (res['success'] == true && mounted) Navigator.pop(context);
  }

  Future<void> _generarPrueba() async {
    final res = await ref.read(ecfProvider.notifier).generarCertificadoPrueba();
    _notify(res['message']?.toString() ?? '', ok: res['success'] == true);
  }

  Future<void> _seleccionarP12() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['p12', 'pfx'],
      withData: true,
    );
    if (result != null && result.files.isNotEmpty) {
      final f = result.files.first;
      List<int>? bytes = f.bytes;
      if (bytes == null && !kIsWeb && f.path != null) {
        bytes = await io.File(f.path!).readAsBytes();
      }
      if (bytes != null) {
        setState(() {
          _pickedBytes = bytes;
          _pickedName = f.name;
        });
      }
    }
  }

  Future<void> _subirP12() async {
    if (_pickedBytes == null || _pickedName == null) {
      _notify('Selecciona primero un archivo .p12 o .pfx.', ok: false);
      return;
    }
    if (_p12PassCtrl.text.isEmpty) {
      _notify('Ingresa la contraseña del certificado .p12.', ok: false);
      return;
    }
    final res = await ref.read(ecfProvider.notifier).subirCertificadoP12(
      fileBytes: _pickedBytes!,
      fileName: _pickedName!,
      password: _p12PassCtrl.text,
    );
    _notify(res['message']?.toString() ?? '', ok: res['success'] == true);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(ecfProvider);
    final cert = state.certificado;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560, maxHeight: 530),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.security_rounded,
                    size: 18,
                    color: AppColors.azulOscuro,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Configuración Emisor e-CF & Certificado Digital',
                      style: TextStyle(
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
              TabBar(
                controller: _tabCtrl,
                labelColor: AppColors.azulOscuro,
                indicatorColor: AppColors.primary,
                labelStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
                tabs: const [
                  Tab(height: 34, text: '1. Emisor y Ambiente DGII'),
                  Tab(height: 34, text: '2. Certificado Digital (.p12)'),
                ],
              ),
              const SizedBox(height: 10),
              Expanded(
                child: TabBarView(
                  controller: _tabCtrl,
                  children: [
                    _buildEmisorTab(state.isActionLoading),
                    _buildCertTab(cert, state.isActionLoading),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmisorTab(bool loading) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ambiente de Transmisión',
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
                        value: _ambiente,
                        items: const [
                          DropdownMenuItem(
                            value: 'mock',
                            child: Text('Simulador Local (Sin OFV / Offline)'),
                          ),
                          DropdownMenuItem(
                            value: 'TesteCF',
                            child: Text('Sandbox DGII (Pre-Certificación)'),
                          ),
                          DropdownMenuItem(
                            value: 'CerteCF',
                            child: Text('Certificación DGII (CerteCF)'),
                          ),
                          DropdownMenuItem(
                            value: 'eCF',
                            child: Text('Producción Oficial DGII (eCF)'),
                          ),
                        ],
                        onChanged: (v) {
                          if (v != null) setState(() => _ambiente = v);
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
                  controller: _rncCtrl,
                  label: 'RNC Emisor (9 u 11 dígitos)',
                  hintText: '131000001',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: CustomTextField(
                  controller: _razonCtrl,
                  label: 'Razón Social Fiscal',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: CustomTextField(
                  controller: _comercialCtrl,
                  label: 'Nombre Comercial',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          CustomTextField(controller: _dirCtrl, label: 'Dirección Fiscal'),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: CustomTextField(
                  controller: _telCtrl,
                  label: 'Teléfono',
                  hintText: '809-555-0000',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: CustomTextField(
                  controller: _correoCtrl,
                  label: 'Correo Electrónico Emisor',
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          SwitchListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
            activeColor: AppColors.primary,
            title: const Text(
              'Firmar y transmitir automáticamente al facturar en POS',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            value: _envioAuto,
            onChanged: (v) => setState(() => _envioAuto = v),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: loading ? null : _guardarConfig,
              icon: const Icon(Icons.save_rounded, size: 16),
              label: const Text(
                'Guardar Configuración',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.azulOscuro,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCertTab( dynamic cert, bool loading) {
    final bool ok = cert.valido == true;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: ok ? Colors.teal.shade50 : Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: ok ? Colors.teal.shade200 : Colors.orange.shade200,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ok
                      ? 'Certificado Activo: ${cert.cn} (${cert.organizacion})'
                      : 'Estado: ${cert.error ?? "No instalado"}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: ok ? Colors.teal.shade900 : Colors.orange.shade900,
                  ),
                ),
                if (ok) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Archivo: ${cert.archivo} • Emisor CA: ${cert.emisorCa}\nVigencia: ${cert.validoDesde} → ${cert.validoHasta} (${cert.diasRestantes} días)',
                    style: TextStyle(fontSize: 11, color: Colors.teal.shade800),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Expanded(
                child: Text(
                  '¿Aún sin certificado comercial? Genera uno RSA-2048 local para desarrollar y probar:',
                  style: TextStyle(fontSize: 11, color: Colors.black87),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: loading ? null : _generarPrueba,
                icon: const Icon(Icons.auto_fix_high_rounded, size: 15),
                label: const Text(
                  'Generar .p12 Prueba',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const Divider(height: 22),
          const Text(
            'Instalar Certificado Oficial (.p12 / .pfx de Digifirma, Viafirma o Cámara)',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.azulOscuro,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: _seleccionarP12,
                icon: const Icon(Icons.upload_file_rounded, size: 16),
                label: Text(
                  _pickedName ?? 'Seleccionar .p12 / .pfx',
                  style: const TextStyle(fontSize: 11),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: CustomTextField(
                  controller: _p12PassCtrl,
                  label: '',
                  hintText: 'Contraseña del .p12',
                  isPassword: true,
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: loading ? null : _subirP12,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 11,
                  ),
                ),
                child: const Text(
                  'Instalar',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
