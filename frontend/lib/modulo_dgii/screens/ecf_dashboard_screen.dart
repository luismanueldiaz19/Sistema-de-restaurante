import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../palletes/app_colors.dart';
import '../../widgets/custom_empty_state.dart';
import '../../widgets/custom_filter_dropdown.dart';
import '../../widgets/custom_text_field.dart';
import '../models/ecf_models.dart';
import '../providers/ecf_provider.dart';
import '../widgets/ecf_config_cert_dialog.dart';
import '../widgets/ecf_documento_row.dart';
import '../widgets/ecf_kpi_strip.dart';
import '../widgets/ecf_xml_viewer_dialog.dart';

class EcfDashboardScreen extends ConsumerStatefulWidget {
  const EcfDashboardScreen({super.key});

  @override
  ConsumerState<EcfDashboardScreen> createState() => _EcfDashboardScreenState();
}

class _EcfDashboardScreenState extends ConsumerState<EcfDashboardScreen> {
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(ecfProvider.notifier).cargarTodo());
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _snack(String msg, {bool ok = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontSize: 12)),
        backgroundColor: ok ? Colors.teal.shade700 : Colors.red.shade700,
      ),
    );
  }

  void _openConfig() {
    showDialog(
      context: context,
      builder: (_) => const EcfConfigCertDialog(),
    );
  }

  void _openXml(EcfDocumentoItem doc) {
    showDialog(
      context: context,
      builder: (_) => EcfXmlViewerDialog(doc: doc),
    );
  }

  Future<void> _probarHandshake() async {
    final res = await ref.read(ecfProvider.notifier).probarConexion();
    _snack(res['message']?.toString() ?? '', ok: res['success'] == true);
  }

  String _ambienteLabel(String amb) {
    switch (amb) {
      case 'eCF':
        return 'PRODUCCIÓN OFICIAL';
      case 'CerteCF':
        return 'CERTIFICACIÓN DGII';
      case 'TesteCF':
        return 'SANDBOX PRE-CERT.';
      default:
        return 'SIMULADOR LOCAL';
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(ecfProvider);
    final isProd = state.config.ambiente == 'eCF';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        elevation: 0.5,
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: AppColors.azulOscuro),
        title: Row(
          children: [
            const Text(
              'Facturación Electrónica (e-CF)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.azulOscuro,
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: isProd ? Colors.green.shade50 : Colors.amber.shade50,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isProd ? Colors.green.shade300 : Colors.amber.shade400,
                ),
              ),
              child: Text(
                _ambienteLabel(state.config.ambiente),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: isProd ? Colors.green.shade800 : Colors.amber.shade900,
                ),
              ),
            ),
          ],
        ),
        actions: [
          OutlinedButton.icon(
            onPressed: state.isActionLoading ? null : _probarHandshake,
            icon: const Icon(Icons.bolt_rounded, size: 15),
            label: const Text(
              'Probar Semilla / Token',
              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: _openConfig,
            icon: const Icon(Icons.security_rounded, size: 15),
            label: const Text(
              'Configuración y .p12',
              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.azulOscuro,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
          ),
          const SizedBox(width: 6),
          IconButton(
            visualDensity: VisualDensity.compact,
            tooltip: 'Actualizar listado',
            icon: const Icon(Icons.refresh_rounded, size: 19),
            onPressed: () => ref.read(ecfProvider.notifier).cargarTodo(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            EcfKpiStrip(
              config: state.config,
              certificado: state.certificado,
              estadisticas: state.estadisticas,
              onOpenConfig: _openConfig,
            ),
            const SizedBox(height: 10),
            _buildFilterBar(state),
            const SizedBox(height: 10),
            Expanded(child: _buildTableCard(state)),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterBar(EcfState state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: CustomTextField(
              controller: _searchCtrl,
              label: '',
              hintText: 'Buscar eNCF, TrackId, RNC o Código Seguridad...',
              prefixIcon: Icons.search_rounded,
              onChanged: (val) =>
                  ref.read(ecfProvider.notifier).aplicarFiltros(search: val),
            ),
          ),
          const SizedBox(width: 8),
          CustomFilterDropdown<String>(
            height: 36,
            value: state.filtroTipoEcf,
            items: const [
              DropdownMenuItem(value: '', child: Text('Tipo: Todos')),
              DropdownMenuItem(value: '31', child: Text('E31 - Crédito Fiscal')),
              DropdownMenuItem(value: '32', child: Text('E32 - Consumo')),
              DropdownMenuItem(value: '34', child: Text('E34 - Nota Crédito')),
              DropdownMenuItem(value: '44', child: Text('E44 - Reg. Especial')),
              DropdownMenuItem(value: '45', child: Text('E45 - Gubernamental')),
            ],
            onChanged: (v) =>
                ref.read(ecfProvider.notifier).aplicarFiltros(tipoEcf: v ?? ''),
          ),
          const SizedBox(width: 8),
          CustomFilterDropdown<String>(
            height: 36,
            value: state.filtroEstado,
            items: const [
              DropdownMenuItem(value: '', child: Text('Estado: Todos')),
              DropdownMenuItem(value: 'ACEPTADO', child: Text('Aceptados')),
              DropdownMenuItem(value: 'EN_PROCESO', child: Text('En Proceso')),
              DropdownMenuItem(value: 'PENDIENTE', child: Text('Pendientes')),
              DropdownMenuItem(value: 'RECHAZADO', child: Text('Rechazados')),
              DropdownMenuItem(value: 'ERROR_ENVIO', child: Text('Error Envío')),
            ],
            onChanged: (v) =>
                ref.read(ecfProvider.notifier).aplicarFiltros(estado: v ?? ''),
          ),
        ],
      ),
    );
  }

  Widget _buildTableCard(EcfState state) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(10),
              ),
            ),
            child: const Row(
              children: [
                Expanded(flex: 3, child: _Hdr('e-NCF / Fecha')),
                Expanded(flex: 3, child: _Hdr('Comprador / RNC')),
                Expanded(flex: 2, child: _Hdr('Cód. Seguridad')),
                Expanded(
                  flex: 2,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: _Hdr('Monto / ITBIS'),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: Align(
                    alignment: Alignment.center,
                    child: _Hdr('Estado DGII'),
                  ),
                ),
                SizedBox(width: 8),
                SizedBox(
                  width: 128,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: _Hdr('Acciones'),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : state.documentos.isEmpty
                ? const CustomEmptyState(
                    title: 'Aún no hay comprobantes e-CF emitidos',
                    subtitle:
                        'Al facturar con secuencias Serie E (E31, E32, E34), aparecerán aquí firmados con su XML y QR.',
                    icon: Icons.verified_outlined,
                  )
                : ListView.builder(
                    itemCount: state.documentos.length,
                    itemBuilder: (_, i) {
                      final d = state.documentos[i];
                      return EcfDocumentoRow(
                        doc: d,
                        onViewXml: () => _openXml(d),
                        onOpenQr: () {
                          if (d.qrUrl.isNotEmpty) {
                            launchUrl(Uri.parse(d.qrUrl));
                          }
                        },
                        onCheckStatus: () async {
                          final r = await ref
                              .read(ecfProvider.notifier)
                              .consultarTrackId(d.id);
                          _snack(
                            r['message']?.toString() ?? '',
                            ok: r['success'] == true,
                          );
                        },
                        onResend: () async {
                          final r = await ref
                              .read(ecfProvider.notifier)
                              .reenviarDocumento(d.id);
                          _snack(
                            r['message']?.toString() ?? '',
                            ok: r['success'] == true,
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _Hdr extends StatelessWidget {
  final String text;
  const _Hdr(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 10.5,
        fontWeight: FontWeight.w800,
        color: Colors.grey.shade700,
      ),
    );
  }
}

