import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../palletes/app_colors.dart';
import '../../utils/helpers.dart';
import '../../providers/auth_provider.dart';
import '../../modulo_caja/providers/caja_provider.dart';
import '../../modulo_caja/widgets/cierre_caja_list_card.dart';
import '../../modulo_caja/widgets/cierre_caja_detail_panel.dart';
import '../../modulo_cliente/widgets/paginador.dart';
import '../../widgets/custom_loading.dart';
import '../../widgets/custom_text_field.dart';

class HistorialCajaScreen extends ConsumerStatefulWidget {
  const HistorialCajaScreen({super.key});

  @override
  ConsumerState<HistorialCajaScreen> createState() =>
      _HistorialCajaScreenState();
}

class _HistorialCajaScreenState extends ConsumerState<HistorialCajaScreen> {
  final _searchController = TextEditingController();
  final _fechaDesdeController = TextEditingController();
  final _fechaHastaController = TextEditingController();
  final _scrollController = ScrollController();

  Map<String, dynamic>? selectedSession;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final token = ref.read(authProvider).token;
      if (token != null) {
        ref.read(cajaProvider.notifier).fetchHistorial(token);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _fechaDesdeController.dispose();
    _fechaHastaController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _clearAllFilters(String? token) {
    if (token == null) return;
    _searchController.clear();
    _fechaDesdeController.clear();
    _fechaHastaController.clear();
    ref.read(cajaProvider.notifier).clearFilters(token);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(cajaProvider);
    final auth = ref.watch(authProvider);

    // Si hay una sesión seleccionada, verificar si sigue existiendo en el historial para mantenerla fresca
    if (selectedSession != null && state.historial.isNotEmpty) {
      final updated = state.historial.firstWhere(
        (item) => item['id'] == selectedSession!['id'],
        orElse: () => null,
      );
      if (updated != null && updated != selectedSession) {
        selectedSession = updated;
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          'HISTORIAL DE CIERRES DE CAJA',
          style: TextStyle(
            color: AppColors.azulOscuro,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.azulOscuro),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Recargar Cierres',
            onPressed: () {
              if (auth.token != null) {
                ref
                    .read(cajaProvider.notifier)
                    .fetchHistorial(auth.token!, page: state.currentPage);
              }
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // ── BARRA SUPERIOR DE FILTROS ───────────────────────────────────────
          _buildFilterBar(auth.token, state),

          // ── CUERPO PRINCIPAL: VISTA DIVIDIDA (MASTER - DETAIL) ──────────────
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── LADO IZQUIERDO: LISTA DE SESIONES / CIERRES ──────────────
                Container(
                  width: 340,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(right: BorderSide(color: Colors.black12)),
                  ),
                  child: Column(
                    children: [
                      // Buscador
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: CustomTextField(
                          label: "",
                          hintText: "Buscar por caja, turno o ID...",
                          controller: _searchController,
                          prefixIcon: Icons.search_rounded,
                          onChanged: (value) {
                            if (auth.token != null) {
                              ref
                                  .read(cajaProvider.notifier)
                                  .searchHistorial(value, auth.token!);
                            }
                          },
                          onSuffixIconTap: () {
                            _searchController.clear();
                            if (auth.token != null) {
                              ref
                                  .read(cajaProvider.notifier)
                                  .searchHistorial('', auth.token!);
                            }
                            setState(() {});
                          },
                          suffixIcon: _searchController.text.isNotEmpty
                              ? Icons.clear_rounded
                              : null,
                        ),
                      ),

                      // Lista scrollable con Stack de carga
                      Expanded(
                        child: Stack(
                          children: [
                            if (!state.isLoading && state.historial.isEmpty)
                              Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.point_of_sale_outlined,
                                        size: 48,
                                        color: Colors.grey.shade300,
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        "No se encontraron cierres",
                                        style: TextStyle(
                                          color: Colors.grey.shade500,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "Prueba ajustando los filtros de fecha o estado.",
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: Colors.grey.shade400,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            else
                              ListView.separated(
                                controller: _scrollController,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                itemCount: state.historial.length,
                                separatorBuilder: (_, _) =>
                                    const SizedBox(height: 6),
                                itemBuilder: (context, index) {
                                  final s = state.historial[index];
                                  final isSelected =
                                      selectedSession?['id'] == s['id'];

                                  return CierreCajaListCard(
                                    session: s,
                                    isSelected: isSelected,
                                    onTap: () {
                                      setState(() {
                                        selectedSession = s;
                                      });
                                    },
                                  );
                                },
                              ),
                            if (state.isLoading)
                              Positioned.fill(
                                child: Container(
                                  color: Colors.white.withValues(alpha: 0.5),
                                  child: const CustomLoading(
                                    text: "Cargando cierres...",
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),

                      // Paginador
                      if (state.historial.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            border: Border(
                              top: BorderSide(color: Colors.grey.shade200),
                            ),
                          ),
                          child: Column(
                            children: [
                              Paginador(
                                currentPage: state.currentPage,
                                totalPages: state.totalPages,
                                onPageChanged: (page) {
                                  if (auth.token != null) {
                                    ref
                                        .read(cajaProvider.notifier)
                                        .fetchHistorial(auth.token!, page: page);
                                  }
                                },
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Total de registros: ${state.totalRecords}',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey.shade500,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),

                // ── LADO DERECHO: PANEL DE DETALLES COMPLETOS DEL CIERRE ─────
                Expanded(
                  child: selectedSession == null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.touch_app_outlined,
                                size: 80,
                                color: Colors.grey.shade300,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                "Selecciona un cierre de caja de la lista\npara ver todos sus detalles financieros y arqueo.",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        )
                      : CierreCajaDetailPanel(
                          key: ValueKey(selectedSession!['id']),
                          session: selectedSession!,
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar(String? token, CajaState state) {
    final estadoActual = state.filters['estado'];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // Filtros de estado mediante chips
            const Text(
              "Estado:",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
            const SizedBox(width: 8),
            _buildChip(
              label: "Todos",
              isSelected: estadoActual == null,
              onTap: () {
                if (token != null) {
                  final newFilters = Map<String, String>.from(state.filters);
                  newFilters.remove('estado');
                  ref
                      .read(cajaProvider.notifier)
                      .updateFilters(token, newFilters, replace: true);
                }
              },
            ),
            _buildChip(
              label: "Abiertas",
              isSelected: estadoActual == 'abierta',
              onTap: () {
                if (token != null) {
                  ref
                      .read(cajaProvider.notifier)
                      .updateFilters(token, {'estado': 'abierta'});
                }
              },
            ),
            _buildChip(
              label: "Cerradas",
              isSelected: estadoActual == 'cerrada',
              onTap: () {
                if (token != null) {
                  ref
                      .read(cajaProvider.notifier)
                      .updateFilters(token, {'estado': 'cerrada'});
                }
              },
            ),
            const SizedBox(width: 20),

            // Selector de Fecha Desde
            SizedBox(
              width: 140,
              child: _buildDateInput(
                label: "Fecha Desde",
                controller: _fechaDesdeController,
                onTap: () async {
                  final date = await showCustomDatePicker(context);
                  if (date != null && token != null) {
                    final formatted = formatDate(date);
                    _fechaDesdeController.text = formatted;
                    ref
                        .read(cajaProvider.notifier)
                        .updateFilters(token, {'fecha_desde': formatted});
                  }
                },
              ),
            ),
            const SizedBox(width: 8),

            // Selector de Fecha Hasta
            SizedBox(
              width: 140,
              child: _buildDateInput(
                label: "Fecha Hasta",
                controller: _fechaHastaController,
                onTap: () async {
                  final date = await showCustomDatePicker(context);
                  if (date != null && token != null) {
                    final formatted = formatDate(date);
                    _fechaHastaController.text = formatted;
                    ref
                        .read(cajaProvider.notifier)
                        .updateFilters(token, {'fecha_hasta': formatted});
                  }
                },
              ),
            ),
            const SizedBox(width: 8),

            // Botón Limpiar Filtros
            OutlinedButton.icon(
              onPressed: () => _clearAllFilters(token),
              icon: const Icon(Icons.clear_all_rounded, size: 15),
              label: const Text("Limpiar"),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.grey.shade700,
                side: BorderSide(color: Colors.grey.shade300),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 6.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.azulOscuro : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? AppColors.azulOscuro : Colors.grey.shade300,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : Colors.grey.shade700,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDateInput({
    required String label,
    required TextEditingController controller,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today_outlined, size: 15, color: Colors.grey.shade600),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                controller.text.isNotEmpty ? controller.text : label,
                style: TextStyle(
                  fontSize: 11,
                  color: controller.text.isNotEmpty
                      ? AppColors.azulOscuro
                      : Colors.grey.shade500,
                  fontWeight: controller.text.isNotEmpty
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (controller.text.isNotEmpty)
              GestureDetector(
                onTap: () {
                  controller.clear();
                  final token = ref.read(authProvider).token;
                  if (token != null) {
                    final filters = Map<String, String>.from(
                      ref.read(cajaProvider).filters,
                    );
                    filters.remove(label == "Fecha Desde" ? 'fecha_desde' : 'fecha_hasta');
                    ref
                        .read(cajaProvider.notifier)
                        .updateFilters(token, filters, replace: true);
                  }
                },
                child: Icon(Icons.close, size: 14, color: Colors.grey.shade400),
              ),
          ],
        ),
      ),
    );
  }
}
