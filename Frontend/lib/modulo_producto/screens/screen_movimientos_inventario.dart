import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:intl/intl.dart';
import '../../palletes/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../utils/helpers.dart';
import '../../widgets/custom_loading.dart';
import '../models/producto.dart';
import '../providers/inventario_provider.dart';
import 'nuevo_ajuste_dialog.dart';

class ScreenMovimientosInventario extends ConsumerStatefulWidget {
  const ScreenMovimientosInventario({super.key});

  @override
  ConsumerState<ScreenMovimientosInventario> createState() => _ScreenMovimientosInventarioState();
}

class _ScreenMovimientosInventarioState extends ConsumerState<ScreenMovimientosInventario>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final currencyFormat = NumberFormat.currency(locale: 'es_DO', symbol: 'RD\$ ', decimalDigits: 2);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cargarDatos();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _cargarDatos() {
    final auth = ref.read(authProvider);
    if (auth.token != null) {
      ref.read(inventarioProvider.notifier).loadAll(auth.token!);
    }
  }

  void _abrirNuevoAjuste([Producto? producto]) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => NuevoAjusteDialog(productoInicial: producto),
    );

    if (result == true) {
      _cargarDatos();
    }
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    String? subtitle,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Colors.blueGrey.shade600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.azulOscuro,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStockBadge(double stock, double minimo) {
    Color bg;
    Color fg;
    String label;

    if (stock < 0) {
      bg = Colors.red.shade50;
      fg = Colors.red.shade700;
      label = "${stock.toStringAsFixed(1)} (Déficit)";
    } else if (stock == 0) {
      bg = Colors.red.shade50;
      fg = Colors.red.shade700;
      label = "0.0 (Sin existencias)";
    } else if (stock <= minimo) {
      bg = Colors.amber.shade50;
      fg = Colors.amber.shade800;
      label = "${stock.toStringAsFixed(1)} (Bajo mín.)";
    } else {
      bg = Colors.green.shade50;
      fg = Colors.green.shade700;
      label = stock.toStringAsFixed(1);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: fg.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildTabExistencias(InventarioState state) {
    final items = state.existenciasProductos;
    final term = _searchController.text.trim().toLowerCase();

    final filtered = items.where((it) {
      if (term.isEmpty) return true;
      final nombre = (it['nombre'] ?? '').toString().toLowerCase();
      final codigo = (it['codigo'] ?? '').toString().toLowerCase();
      final categoria = (it['categoria'] ?? '').toString().toLowerCase();
      return nombre.contains(term) || codigo.contains(term) || categoria.contains(term);
    }).toList();

    return Column(
      children: [
        // Buscador compacto
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 36,
                  child: TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    style: const TextStyle(fontSize: 12),
                    decoration: InputDecoration(
                      hintText: "Buscar por código, nombre o categoría...",
                      hintStyle: const TextStyle(fontSize: 12),
                      prefixIcon: const Icon(Icons.search, size: 18),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      isDense: true,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () => _abrirNuevoAjuste(),
                icon: const Icon(Icons.tune, size: 16),
                label: const Text("Ajuste Manual", style: TextStyle(fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ),

        // Tabla de existencias
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: DataTable2(
                columnSpacing: 10,
                horizontalMargin: 12,
                headingRowHeight: 34,
                dataRowHeight: 38,
                headingRowColor: WidgetStateProperty.all(Colors.grey.shade100),
                columns: const [
                  DataColumn2(label: Text("CÓDIGO", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)), fixedWidth: 90),
                  DataColumn2(label: Text("PRODUCTO", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                  DataColumn2(label: Text("CATEGORÍA", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)), fixedWidth: 120),
                  DataColumn2(label: Text("UNIDAD", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)), fixedWidth: 80),
                  DataColumn2(label: Text("STOCK", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)), fixedWidth: 130),
                  DataColumn2(label: Text("MÍNIMO", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)), numeric: true, fixedWidth: 70),
                  DataColumn2(label: Text("COSTO", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)), numeric: true, fixedWidth: 95),
                  DataColumn2(label: Text("VALOR COSTO", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)), numeric: true, fixedWidth: 110),
                  DataColumn2(label: Text("ACCIÓN", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)), fixedWidth: 70),
                ],
                rows: filtered.map((item) {
                  final stock = FormatterNumber.parseDouble(item['stock_actual']);
                  final minimo = FormatterNumber.parseDouble(item['stock_minimo']);
                  final costo = FormatterNumber.parseDouble(item['costo']);
                  final valorCosto = FormatterNumber.parseDouble(item['valor_costo']);

                  return DataRow2(
                    cells: [
                      DataCell(Text(item['codigo'] ?? '#${item['id']}', style: const TextStyle(fontSize: 11, color: Colors.blueGrey))),
                      DataCell(
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                item['nombre'] ?? '',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      DataCell(Text(item['categoria'] ?? '--', style: const TextStyle(fontSize: 11, color: Colors.black87))),
                      DataCell(Text(item['unidad_medida'] ?? 'un.', style: const TextStyle(fontSize: 11, color: Colors.blueGrey))),
                      DataCell(_buildStockBadge(stock, minimo)),
                      DataCell(Text(minimo.toStringAsFixed(1), style: const TextStyle(fontSize: 11))),
                      DataCell(Text(currencyFormat.format(costo), style: const TextStyle(fontSize: 11))),
                      DataCell(Text(currencyFormat.format(valorCosto), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                      DataCell(
                        IconButton(
                          icon: const Icon(Icons.edit_note, size: 18, color: AppColors.primary),
                          tooltip: "Realizar Ajuste de este Producto",
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () {
                            final prodModel = Producto(
                              id: item['id'],
                              nombre: item['nombre'],
                              codigo: item['codigo'],
                              stockActual: stock,
                              stockMinimo: minimo,
                              costo: costo,
                              manejaInventario: true,
                              tipoProducto: item['tipo_producto'],
                            );
                            _abrirNuevoAjuste(prodModel);
                          },
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTabKardex(InventarioState state) {
    return Column(
      children: [
        // Filtros tipo y búsqueda
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              // Botones de filtro rápido
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'TODOS', label: Text("Todos", style: TextStyle(fontSize: 11))),
                  ButtonSegment(value: 'ENTRADA', label: Text("Entradas (+)", style: TextStyle(fontSize: 11, color: Colors.green))),
                  ButtonSegment(value: 'SALIDA', label: Text("Salidas (-)", style: TextStyle(fontSize: 11, color: Colors.red))),
                ],
                selected: {state.filtroTipo},
                style: const ButtonStyle(
                  visualDensity: VisualDensity.compact,
                ),
                onSelectionChanged: (set) {
                  final auth = ref.read(authProvider);
                  if (auth.token != null) {
                    ref.read(inventarioProvider.notifier).loadMovimientos(auth.token!, tipo: set.first);
                  }
                },
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () => _abrirNuevoAjuste(),
                icon: const Icon(Icons.add, size: 16),
                label: const Text("Nuevo Ajuste", style: TextStyle(fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ),

        // Tabla Kardex
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: DataTable2(
                columnSpacing: 10,
                horizontalMargin: 12,
                headingRowHeight: 34,
                dataRowHeight: 38,
                headingRowColor: WidgetStateProperty.all(Colors.grey.shade100),
                columns: const [
                  DataColumn2(label: Text("FECHA Y HORA", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)), fixedWidth: 140),
                  DataColumn2(label: Text("PRODUCTO", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                  DataColumn2(label: Text("MOVIMIENTO", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)), fixedWidth: 110),
                  DataColumn2(label: Text("CANTIDAD", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)), numeric: true, fixedWidth: 100),
                  DataColumn2(label: Text("REFERENCIA / MOTIVO", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                ],
                rows: state.movimientos.map((m) {
                  final dateStr = m.fecha != null ? DateFormat('yyyy-MM-dd HH:mm').format(m.fecha!) : '--';
                  final isEntrada = (m.tipo ?? '').toUpperCase() == 'ENTRADA';

                  return DataRow2(
                    cells: [
                      DataCell(Text(dateStr, style: const TextStyle(fontSize: 11, color: Colors.blueGrey))),
                      DataCell(
                        Text(
                          m.producto?.nombre ?? 'Producto #${m.productoId}',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: isEntrada ? Colors.green.shade50 : Colors.red.shade50,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: isEntrada ? Colors.green.shade300 : Colors.red.shade300),
                          ),
                          child: Text(
                            isEntrada ? "ENTRADA" : "SALIDA",
                            style: TextStyle(
                              color: isEntrada ? Colors.green.shade800 : Colors.red.shade800,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      DataCell(
                        Text(
                          "${isEntrada ? '+' : '-'}${m.cantidad?.toStringAsFixed(2) ?? '0'}",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isEntrada ? Colors.green.shade700 : Colors.red.shade700,
                          ),
                        ),
                      ),
                      DataCell(
                        Text(
                          m.referencia ?? '--',
                          style: const TextStyle(fontSize: 11, color: Colors.black87),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTabAlertas(InventarioState state) {
    final alertas = state.alertas;

    if (alertas.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_outline, size: 48, color: Colors.green.shade400),
            const SizedBox(height: 10),
            const Text(
              "¡Excelente! No hay productos bajo el stock mínimo ni en déficit.",
              style: TextStyle(fontSize: 13, color: Colors.blueGrey, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: DataTable2(
          columnSpacing: 10,
          horizontalMargin: 12,
          headingRowHeight: 34,
          dataRowHeight: 38,
          headingRowColor: WidgetStateProperty.all(Colors.amber.shade50),
          columns: const [
            DataColumn2(label: Text("CÓDIGO", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)), fixedWidth: 90),
            DataColumn2(label: Text("PRODUCTO EN ALERTA", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
            DataColumn2(label: Text("CATEGORÍA", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)), fixedWidth: 120),
            DataColumn2(label: Text("STOCK ACTUAL", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)), fixedWidth: 140),
            DataColumn2(label: Text("STOCK MÍNIMO", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)), numeric: true, fixedWidth: 100),
            DataColumn2(label: Text("FALTANTE RECOMENDADO", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)), numeric: true, fixedWidth: 140),
            DataColumn2(label: Text("ACCIÓN", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)), fixedWidth: 80),
          ],
          rows: alertas.map((p) {
            final stock = p.stockActual ?? 0.0;
            final minimo = p.stockMinimo ?? 0.0;
            final faltante = (minimo - stock) > 0 ? (minimo - stock) : 0.0;

            return DataRow2(
              cells: [
                DataCell(Text(p.codigo ?? '#${p.id}', style: const TextStyle(fontSize: 11, color: Colors.blueGrey))),
                DataCell(
                  Text(
                    p.nombre ?? '',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                ),
                DataCell(Text(p.categoria?.nombre ?? '--', style: const TextStyle(fontSize: 11))),
                DataCell(_buildStockBadge(stock, minimo)),
                DataCell(Text(minimo.toStringAsFixed(1), style: const TextStyle(fontSize: 11))),
                DataCell(
                  Text(
                    "+${faltante.toStringAsFixed(1)} ${p.unidadMedida?.nombre ?? 'un.'}",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade700,
                    ),
                  ),
                ),
                DataCell(
                  IconButton(
                    icon: const Icon(Icons.add_shopping_cart, size: 18, color: AppColors.primary),
                    tooltip: "Ajustar o reponer",
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => _abrirNuevoAjuste(p),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(inventarioProvider);
    final resumen = state.existenciasResumen;

    final totalProductos = resumen['total_productos'] ?? 0;
    final totalUnidades = resumen['total_unidades'] ?? 0.0;
    final valorTotalCosto = resumen['valor_total_costo'] ?? 0.0;
    final enAlerta = resumen['productos_en_alerta'] ?? 0;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          "Control de Inventario & Kardex",
          style: TextStyle(
            color: AppColors.azulOscuro,
            fontWeight: FontWeight.bold,
            fontSize: 17,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.azulOscuro),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            tooltip: "Actualizar datos",
            onPressed: _cargarDatos,
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12, left: 4),
            child: ElevatedButton.icon(
              onPressed: () => _abrirNuevoAjuste(),
              icon: const Icon(Icons.add, size: 16),
              label: const Text("Nuevo Ajuste", style: TextStyle(fontSize: 12)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: Colors.blueGrey,
          indicatorColor: AppColors.primary,
          indicatorWeight: 2.5,
          labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          unselectedLabelStyle: const TextStyle(fontSize: 12),
          tabs: [
            const Tab(icon: Icon(Icons.inventory_2_outlined, size: 18), text: "Existencias y Valorización"),
            const Tab(icon: Icon(Icons.swap_horiz, size: 18), text: "Movimientos / Kardex"),
            Tab(
              icon: const Icon(Icons.warning_amber_rounded, size: 18),
              text: enAlerta > 0 ? "Alertas de Reposición ($enAlerta)" : "Alertas de Reposición",
            ),
          ],
        ),
      ),
      body: state.isLoading && state.existenciasProductos.isEmpty
          ? const Center(child: CustomLoading(text: "Cargando datos de inventario..."))
          : Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                children: [
                  // Tarjetas de Métricas KPI Compactas
                  Row(
                    children: [
                      _buildMetricCard(
                        title: "Ítems Inventariables",
                        value: "$totalProductos",
                        icon: Icons.category_outlined,
                        color: Colors.blue,
                      ),
                      const SizedBox(width: 8),
                      _buildMetricCard(
                        title: "Unidades en Almacén",
                        value: NumberFormat('#,##0.0').format(totalUnidades),
                        icon: Icons.all_inbox_outlined,
                        color: Colors.teal,
                      ),
                      const SizedBox(width: 8),
                      _buildMetricCard(
                        title: "Valorización a Costo",
                        value: currencyFormat.format(valorTotalCosto),
                        icon: Icons.account_balance_wallet_outlined,
                        color: Colors.indigo,
                      ),
                      const SizedBox(width: 8),
                      _buildMetricCard(
                        title: "Ítems en Alerta / Déficit",
                        value: "$enAlerta",
                        icon: Icons.report_problem_outlined,
                        color: enAlerta > 0 ? Colors.red : Colors.green,
                        subtitle: enAlerta > 0 ? "Requieren reposición" : "Nivel óptimo",
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Vistas de Pestañas
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildTabExistencias(state),
                        _buildTabKardex(state),
                        _buildTabAlertas(state),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
