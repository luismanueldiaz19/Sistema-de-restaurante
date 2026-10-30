import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../palletes/app_colors.dart';
import '../../utils/formatter_number.dart';
import '../../widgets/custom_empty_state.dart';
import '../../widgets/custom_filter_dropdown.dart';
import '../../widgets/custom_text_field.dart';
import '../models/ncf_secuencia_model.dart';
import '../providers/ncf_provider.dart';
import '../widgets/ncf_form_dialog.dart';

class NcfSecuenciasScreen extends ConsumerStatefulWidget {
  const NcfSecuenciasScreen({super.key});

  @override
  ConsumerState<NcfSecuenciasScreen> createState() =>
      _NcfSecuenciasScreenState();
}

class _NcfSecuenciasScreenState extends ConsumerState<NcfSecuenciasScreen> {
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(ncfProvider.notifier).cargarSecuencias());
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _openForm([NcfSecuenciaModel? sec]) {
    showDialog(
      context: context,
      builder: (_) => NcfFormDialog(secuencia: sec),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(ncfProvider);
    final all = state.secuencias;
    final list = state.filtradas;

    final activas = all.where((s) => s.activo).length;
    final serieE = all.where((s) => s.esElectronico).length;
    final alertas = all.where((s) => s.agotada || s.alertaBaja).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        elevation: 0.5,
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: AppColors.azulOscuro),
        title: const Text(
          'Secuencias de Comprobantes (NCF / e-NCF)',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.azulOscuro,
          ),
        ),
        actions: [
          ElevatedButton.icon(
            onPressed: () => _openForm(),
            icon: const Icon(Icons.add_rounded, size: 16),
            label: const Text(
              'Nueva Secuencia',
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
            tooltip: 'Recargar secuencias',
            icon: const Icon(Icons.refresh_rounded, size: 19),
            onPressed: () => ref.read(ncfProvider.notifier).cargarSecuencias(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _KpiTile(
                    label: 'Total Registradas',
                    val: all.length.toString(),
                    icon: Icons.confirmation_number_outlined,
                    color: AppColors.azulOscuro,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _KpiTile(
                    label: 'Secuencias Activas',
                    val: activas.toString(),
                    icon: Icons.check_circle_outline_rounded,
                    color: Colors.teal.shade700,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _KpiTile(
                    label: 'Serie E (Electrónicas)',
                    val: serieE.toString(),
                    icon: Icons.bolt_rounded,
                    color: Colors.indigo.shade700,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _KpiTile(
                    label: 'Por Agotarse / Agotadas',
                    val: alertas.toString(),
                    icon: Icons.warning_amber_rounded,
                    color: alertas > 0
                        ? Colors.red.shade700
                        : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: _searchCtrl,
                      label: '',
                      hintText: 'Buscar por código (E31, E32, B01) o nombre...',
                      prefixIcon: Icons.search_rounded,
                      onChanged: (v) =>
                          ref.read(ncfProvider.notifier).setFiltros(search: v),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CustomFilterDropdown<String>(
                    height: 36,
                    value: state.filtroEstado,
                    items: const [
                      DropdownMenuItem(value: '', child: Text('Estado: Todas')),
                      DropdownMenuItem(
                        value: 'activas',
                        child: Text('Solo Activas'),
                      ),
                      DropdownMenuItem(
                        value: 'inactivas',
                        child: Text('Inactivas'),
                      ),
                    ],
                    onChanged: (v) => ref
                        .read(ncfProvider.notifier)
                        .setFiltros(estado: v ?? ''),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Expanded(child: _buildTable(state.isLoading, list)),
          ],
        ),
      ),
    );
  }

  Widget _buildTable(bool loading, List<NcfSecuenciaModel> list) {
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
                Expanded(flex: 3, child: _Th('Tipo / Comprobante')),
                Expanded(flex: 2, child: _Th('Próximo a Emitir')),
                Expanded(flex: 2, child: _Th('Rango Autorizado DGII')),
                Expanded(flex: 2, child: _Th('Disponibles')),
                SizedBox(width: 110, child: _Th('Activa / Editar')),
              ],
            ),
          ),
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : list.isEmpty
                ? const CustomEmptyState(
                    title: 'Sin secuencias para este filtro',
                    icon: Icons.confirmation_number_outlined,
                  )
                : ListView.builder(
                    itemCount: list.length,
                    itemBuilder: (_, i) => _buildRow(list[i]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(NcfSecuenciaModel s) {
    final badgeColor = s.agotada
        ? Colors.red.shade700
        : (s.alertaBaja ? Colors.orange.shade800 : Colors.teal.shade700);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: s.esElectronico
                        ? Colors.indigo.shade50
                        : Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    s.codigo,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      color: s.esElectronico
                          ? Colors.indigo.shade800
                          : Colors.amber.shade900,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    s.nombre,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.azulOscuro,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.proximoNcfFormateado,
                  style: TextStyle(
                    fontFamily: 'Consolas',
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: s.agotada
                        ? Colors.red.shade700
                        : AppColors.azulOscuro,
                  ),
                ),
                Text(
                  'Último usado: ${FormatterNumber.formatNumber(s.actual.toDouble())}',
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '${FormatterNumber.formatNumber(s.rangoInicio.toDouble())} → ${FormatterNumber.formatNumber(s.rangoFin.toDouble())}',
              style: TextStyle(fontSize: 11.5, color: Colors.grey.shade800),
            ),
          ),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  s.agotada
                      ? 'AGOTADA'
                      : FormatterNumber.formatNumber(s.disponibles.toDouble()),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: badgeColor,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(
            width: 110,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Transform.scale(
                  scale: 0.75,
                  child: Switch(
                    value: s.activo,
                    activeThumbColor: AppColors.primary,
                    onChanged: (_) =>
                        ref.read(ncfProvider.notifier).toggleActivo(s.id),
                  ),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Configurar rango y correlativo',
                  icon: const Icon(Icons.edit_outlined, size: 17),
                  color: AppColors.azulOscuro,
                  onPressed: () => _openForm(s),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _KpiTile extends StatelessWidget {
  final String label;
  final String val;
  final IconData icon;
  final Color color;

  const _KpiTile({
    required this.label,
    required this.val,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, size: 17, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  val,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Th extends StatelessWidget {
  final String t;
  const _Th(this.t);

  @override
  Widget build(BuildContext context) {
    return Text(
      t,
      style: TextStyle(
        fontSize: 10.5,
        fontWeight: FontWeight.w800,
        color: Colors.grey.shade700,
      ),
    );
  }
}

