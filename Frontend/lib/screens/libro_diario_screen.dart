import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../modulo_contabilidad/screens/balance_general_screen.dart';
import '../modulo_contabilidad/screens/estado_resultados_screen.dart';
import '../modulo_contabilidad/screens/estado_resultados_tabla_screen.dart';
import '../modulo_contabilidad/screens/mayor_general_screen.dart';
import '../modulo_contabilidad/widgets/asiento_diario_card.dart';
import '../modulo_contabilidad/widgets/contabilidad_shared_widgets.dart';
import '../palletes/app_colors.dart';
import '../providers/auth_provider.dart';
import '../providers/configuracion_contable_provider.dart';
import '../utils/formatter_number.dart';
import '../widgets/custom_empty_state.dart';
import '../widgets/custom_text_field.dart';

class LibroDiarioScreen extends ConsumerStatefulWidget {
  const LibroDiarioScreen({super.key});

  @override
  ConsumerState<LibroDiarioScreen> createState() => _LibroDiarioScreenState();
}

class _LibroDiarioScreenState extends ConsumerState<LibroDiarioScreen> {
  final TextEditingController _searchController = TextEditingController();
  final Set<int> _collapsedIds = {};
  DateTime? _fechaDesde;
  DateTime? _fechaHasta;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadAsientos());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadAsientos() {
    final token = ref.read(authProvider).token;
    if (token == null) return;
    final fmt = DateFormat('yyyy-MM-dd');
    ref
        .read(configuracionContableProvider.notifier)
        .fetchAsientos(
          token,
          fechaDesde: _fechaDesde != null ? fmt.format(_fechaDesde!) : null,
          fechaHasta: _fechaHasta != null ? fmt.format(_fechaHasta!) : null,
          buscar: _searchController.text.trim(),
        );
  }

  Future<void> _pickFecha(bool isDesde) async {
    final initial = isDesde
        ? (_fechaDesde ?? DateTime.now())
        : (_fechaHasta ?? DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isDesde) {
          _fechaDesde = picked;
        } else {
          _fechaHasta = picked;
        }
      });
      _loadAsientos();
    }
  }

  void _clearFilters() {
    setState(() {
      _fechaDesde = null;
      _fechaHasta = null;
      _searchController.clear();
    });
    _loadAsientos();
  }

  void _toggleAll(List<int> allIds) {
    setState(() {
      if (_collapsedIds.length >= allIds.length && allIds.isNotEmpty) {
        _collapsedIds.clear();
      } else {
        _collapsedIds
          ..clear()
          ..addAll(allIds);
      }
    });
  }

  void _openReport(String key) {
    Widget? screen;
    if (key == 'mayor') screen = const MayorGeneralScreen();
    if (key == 'balance') screen = const BalanceGeneralScreen();
    if (key == 'resultados') screen = const EstadoResultadosScreen();
    if (key == 'tabla') screen = const EstadoResultadosTablaScreen();
    if (screen != null) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => screen!));
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(configuracionContableProvider);
    final asientos = state.asientos;

    double sumDebito = 0;
    double sumCredito = 0;
    for (final a in asientos) {
      for (final d in a.detalles) {
        sumDebito += d.debito;
        sumCredito += d.credito;
      }
    }
    final isCuadrado = (sumDebito - sumCredito).abs() <= 0.05;
    final allCollapsed =
        asientos.isNotEmpty && _collapsedIds.length >= asientos.length;
    final hasFilters =
        _fechaDesde != null ||
        _fechaHasta != null ||
        _searchController.text.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        elevation: 0.5,
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: AppColors.azulOscuro),
        title: const Text(
          'Diario General (Libro Diario)',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.azulOscuro,
          ),
        ),
        actions: [
          OutlinedButton.icon(
            onPressed: asientos.isEmpty
                ? null
                : () => _toggleAll(asientos.map((e) => e.id).toList()),
            icon: Icon(
              allCollapsed
                  ? Icons.unfold_more_rounded
                  : Icons.unfold_less_rounded,
              size: 16,
            ),
            label: Text(
              allCollapsed ? 'Expandir Asientos' : 'Colapsar Asientos',
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 6),
          PopupMenuButton<String>(
            tooltip: 'Ir a reportes financieros',
            onSelected: _openReport,
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'mayor',
                child: Text('Mayor General', style: TextStyle(fontSize: 12)),
              ),
              PopupMenuItem(
                value: 'balance',
                child: Text('Balance General', style: TextStyle(fontSize: 12)),
              ),
              PopupMenuItem(
                value: 'resultados',
                child: Text(
                  'Estado de Resultados',
                  style: TextStyle(fontSize: 12),
                ),
              ),
              PopupMenuItem(
                value: 'tabla',
                child: Text(
                  'Estado de Resultados (Excel)',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ],
            child: Container(
              height: 34,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: AppColors.azulOscuro,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.assessment_outlined,
                    size: 15,
                    color: Colors.white,
                  ),
                  SizedBox(width: 5),
                  Text(
                    'Reportes',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: 2),
                  Icon(
                    Icons.arrow_drop_down_rounded,
                    size: 17,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            visualDensity: VisualDensity.compact,
            tooltip: 'Recargar diario',
            icon: const Icon(Icons.refresh_rounded, size: 19),
            onPressed: _loadAsientos,
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
                  child: ContabilidadKpiChip(
                    label: 'Asientos Listados',
                    value: '${asientos.length}',
                    icon: Icons.menu_book_rounded,
                    color: AppColors.azulOscuro,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ContabilidadKpiChip(
                    label: 'Total Débitos (DR)',
                    value: FormatterNumber.formatCurrency(sumDebito),
                    icon: Icons.north_east_rounded,
                    color: Colors.indigo.shade700,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ContabilidadKpiChip(
                    label: 'Total Créditos (CR)',
                    value: FormatterNumber.formatCurrency(sumCredito),
                    icon: Icons.south_west_rounded,
                    color: AppColors.primaryDark,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ContabilidadKpiChip(
                    label: 'Partida Doble',
                    value: isCuadrado ? 'Cuadrado' : 'Descuadrado',
                    icon: isCuadrado
                        ? Icons.verified_outlined
                        : Icons.error_outline_rounded,
                    color: isCuadrado
                        ? Colors.green.shade700
                        : Colors.red.shade700,
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
                      controller: _searchController,
                      label: '',
                      hintText:
                          'Buscar por referencia (NCF / e-CF), glosa o descripción...',
                      prefixIcon: Icons.search_rounded,
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ContabilidadDateButton(
                    prefix: 'Desde',
                    date: _fechaDesde,
                    emptyLabel: 'Inicio',
                    onTap: () => _pickFecha(true),
                  ),
                  const SizedBox(width: 6),
                  ContabilidadDateButton(
                    prefix: 'Hasta',
                    date: _fechaHasta,
                    emptyLabel: 'Hoy',
                    onTap: () => _pickFecha(false),
                  ),
                  if (hasFilters) ...[
                    const SizedBox(width: 6),
                    TextButton(
                      onPressed: _clearFilters,
                      child: const Text(
                        'Limpiar',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.danger,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(width: 6),
                  SizedBox(
                    height: 36,
                    child: ElevatedButton.icon(
                      onPressed: _loadAsientos,
                      icon: const Icon(Icons.search_rounded, size: 15),
                      label: const Text(
                        'Filtrar',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: state.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : state.errorMessage != null
                  ? CustomEmptyState(
                      title: 'Error al cargar el Libro Diario',
                      subtitle: state.errorMessage!,
                      icon: Icons.error_outline_rounded,
                    )
                  : asientos.isEmpty
                  ? const CustomEmptyState(
                      title: 'No se encontraron asientos contables',
                      subtitle:
                          'Ajusta el rango de fechas o genera operaciones para registrar partidas.',
                      icon: Icons.menu_book_outlined,
                    )
                  : ListView.builder(
                      itemCount: asientos.length,
                      itemBuilder: (_, index) {
                        final asiento = asientos[index];
                        return AsientoDiarioCard(
                          asiento: asiento,
                          isExpanded: !_collapsedIds.contains(asiento.id),
                          onToggle: () {
                            setState(() {
                              if (!_collapsedIds.remove(asiento.id)) {
                                _collapsedIds.add(asiento.id);
                              }
                            });
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
