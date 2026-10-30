import 'dart:convert';
import 'dart:io' as io;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../palletes/app_colors.dart';
import '../models/ecf_models.dart';
import '../providers/ecf_provider.dart';

class EcfXmlViewerDialog extends ConsumerStatefulWidget {
  final EcfDocumentoItem doc;

  const EcfXmlViewerDialog({super.key, required this.doc});

  @override
  ConsumerState<EcfXmlViewerDialog> createState() => _EcfXmlViewerDialogState();
}

class _EcfXmlViewerDialogState extends ConsumerState<EcfXmlViewerDialog> {
  bool _loading = true;
  String _xmlFirmado = '';
  String _xmlRfce = '';
  bool _mostrarRfce = false;
  bool? _firmaValida;
  String _mensajeFirma = '';

  @override
  void initState() {
    super.initState();
    _cargarDetalle();
  }

  Future<void> _cargarDetalle() async {
    final res = await ref
        .read(ecfProvider.notifier)
        .obtenerDetalleDocumento(widget.doc.id);
    if (!mounted) return;
    if (res['success'] == true) {
      final verif = res['verificacion_firma'];
      setState(() {
        _loading = false;
        _xmlFirmado = (res['xml_firmado'] ?? '').toString();
        _xmlRfce = (res['xml_rfce_firmado'] ?? '').toString();
        if (verif is Map) {
          _firmaValida = verif['valid'] == true;
          _mensajeFirma = (verif['error'] ?? 'RSA-SHA256 + Digest C14N OK')
              .toString();
        }
      });
    } else {
      setState(() {
        _loading = false;
        _xmlFirmado = res['message']?.toString() ?? 'Error cargando XML.';
      });
    }
  }

  String get _activeXml =>
      (_mostrarRfce && _xmlRfce.isNotEmpty) ? _xmlRfce : _xmlFirmado;

  Future<void> _guardarXml() async {
    final suffix = (_mostrarRfce && _xmlRfce.isNotEmpty) ? '_RFCE' : '';
    final fileName = '${widget.doc.rncEmisor}${widget.doc.encf}$suffix.xml';
    final bytes = Uint8List.fromList(utf8.encode(_activeXml));

    String? outPath = await FilePicker.saveFile(
      dialogTitle: 'Guardar Comprobante XML Firmado DGII',
      fileName: fileName,
      type: FileType.custom,
      allowedExtensions: ['xml'],
      bytes: bytes,
    );

    if (!kIsWeb && outPath != null) {
      if (!outPath.toLowerCase().endsWith('.xml')) outPath = '$outPath.xml';
      await io.File(outPath).writeAsBytes(bytes, flush: true);
    }

    if (mounted && (kIsWeb || outPath != null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'XML guardado correctamente${outPath != null ? ": $outPath" : ""}',
            style: const TextStyle(fontSize: 12),
          ),
          backgroundColor: Colors.teal.shade700,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.doc;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 780, maxHeight: 580),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.code_rounded,
                    size: 18,
                    color: AppColors.azulOscuro,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Inspector XML Firmado • ${d.encf} (${d.tipoEcf})',
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
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _chip(
                    'Cód. Seguridad: ${d.codigoSeguridad}',
                    Colors.indigo.shade700,
                  ),
                  _chip('Firma: ${d.fechaHoraFirma}', Colors.blueGrey.shade700),
                  _chip(
                    d.xsdValido ? 'Esquema XSD OK' : 'Error XSD',
                    d.xsdValido ? Colors.teal.shade700 : Colors.red.shade700,
                  ),
                  if (_firmaValida != null)
                    _chip(
                      _firmaValida!
                          ? 'XMLDSIG Verificada ($_mensajeFirma)'
                          : 'Firma Inválida',
                      _firmaValida!
                          ? Colors.green.shade700
                          : Colors.red.shade700,
                    ),
                  if (d.trackId != null && d.trackId!.isNotEmpty)
                    _chip('TrackId: ${d.trackId}', Colors.deepPurple.shade700),
                ],
              ),
              if (_xmlRfce.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    ChoiceChip(
                      label: const Text(
                        'XML <ECF> Completo (Archivo Local)',
                        style: TextStyle(fontSize: 11),
                      ),
                      selected: !_mostrarRfce,
                      visualDensity: VisualDensity.compact,
                      onSelected: (_) => setState(() => _mostrarRfce = false),
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text(
                        'XML <RFCE> Resumen (< RD\$ 250k enviado a DGII)',
                        style: TextStyle(fontSize: 11),
                      ),
                      selected: _mostrarRfce,
                      visualDensity: VisualDensity.compact,
                      onSelected: (_) => setState(() => _mostrarRfce = true),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 8),
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D1117),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : SingleChildScrollView(
                          child: SelectableText(
                            _activeXml,
                            style: const TextStyle(
                              fontFamily: 'Consolas',
                              fontSize: 11,
                              height: 1.35,
                              color: Color(0xFFE6EDF3),
                            ),
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: d.qrUrl.isEmpty
                        ? null
                        : () => launchUrl(Uri.parse(d.qrUrl)),
                    icon: const Icon(Icons.qr_code_2_rounded, size: 15),
                    label: const Text(
                      'Probar URL Timbre QR',
                      style: TextStyle(fontSize: 11),
                    ),
                  ),
                  const Spacer(),
                  OutlinedButton.icon(
                    onPressed: _loading
                        ? null
                        : () {
                            Clipboard.setData(ClipboardData(text: _activeXml));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'XML copiado al portapapeles.',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ),
                            );
                          },
                    icon: const Icon(Icons.copy_rounded, size: 15),
                    label: const Text(
                      'Copiar XML',
                      style: TextStyle(fontSize: 11),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _loading ? null : _guardarXml,
                    icon: const Icon(Icons.download_rounded, size: 15),
                    label: const Text(
                      'Guardar .XML',
                      style: TextStyle(
                        fontSize: 11,
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

  Widget _chip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

