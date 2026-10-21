import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../palletes/app_colors.dart';
import '../../utils/helpers.dart';
import '../../providers/auth_provider.dart';
import '../../facturacion/services/facturacion_service.dart';
import '../../facturacion/services/printer_service.dart';

class CierreCajaDetailPanel extends ConsumerStatefulWidget {
  final Map<String, dynamic> session;

  const CierreCajaDetailPanel({super.key, required this.session});

  @override
  ConsumerState<CierreCajaDetailPanel> createState() =>
      _CierreCajaDetailPanelState();
}

class _CierreCajaDetailPanelState extends ConsumerState<CierreCajaDetailPanel>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FacturacionService _facturacionService = FacturacionService();

  List<dynamic> _facturas = [];
  bool _isLoadingFacturas = false;
  bool _facturasLoaded = false;
  bool _isPrinting = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void didUpdateWidget(covariant CierreCajaDetailPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.session['id'] != widget.session['id']) {
      _facturasLoaded = false;
      _facturas = [];
      if (_tabController.index == 1) {
        _loadFacturas();
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadFacturas() async {
    if (_isLoadingFacturas) return;
    final token = ref.read(authProvider).token;
    if (token == null) return;

    setState(() => _isLoadingFacturas = true);
    try {
      final res = await _facturacionService.getHistorial(
        token: token,
        filters: {'caja_sesion_id': widget.session['id'].toString()},
      );

      if (mounted) {
        if (res['success'] == true) {
          final dynamic data = res['data'];
          if (data is Map && data['data'] is List) {
            _facturas = data['data'];
          } else if (data is List) {
            _facturas = data;
          } else {
            _facturas = [];
          }
        }
        setState(() {
          _isLoadingFacturas = false;
          _facturasLoaded = true;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoadingFacturas = false;
          _facturasLoaded = true;
        });
      }
    }
  }

  Future<void> _imprimirReporte() async {
    setState(() => _isPrinting = true);
    final resultado = await ThermalPrinterService.instance.imprimirCierreCaja(
      sesion: widget.session,
    );
    if (mounted) {
      setState(() => _isPrinting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(resultado.mensaje),
          backgroundColor: resultado.exito ? Colors.green : Colors.red,
        ),
      );
    }
  }

  String _calcularDuracion(String? aperturaStr, String? cierreStr) {
    if (aperturaStr == null) return "N/A";
    final apertura = DateTime.tryParse(aperturaStr);
    if (apertura == null) return "N/A";
    final cierre = cierreStr != null ? DateTime.tryParse(cierreStr) : DateTime.now();
    if (cierre == null) return "N/A";

    final dur = cierre.difference(apertura);
    final hours = dur.inHours;
    final minutes = dur.inMinutes.remainder(60);
    if (cierreStr == null) {
      return "$hours h $minutes min (En curso)";
    }
    return "$hours h $minutes min";
  }

  Widget _buildInfoItem(IconData icon, String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.azulOscuro.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, size: 15, color: AppColors.azulOscuro),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  value.isNotEmpty ? value : "N/A",
                  style: TextStyle(
                    fontSize: 12,
                    color: valueColor ?? AppColors.azulOscuro,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.25)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(icon, size: 16, color: color),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 1),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      value,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 8.5,
                      color: Colors.grey.shade500,
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

  @override
  Widget build(BuildContext context) {
    final s = widget.session;
    final bool isAbierta = s['estado'] == 'abierta';
    final double montoInicial = double.tryParse((s['monto_inicial'] ?? 0).toString()) ?? 0;
    final double montoEsperado = double.tryParse((s['monto_final_esperado'] ?? 0).toString()) ?? 0;
    final double? montoFisico = s['monto_final_fisico'] != null
        ? double.tryParse(s['monto_final_fisico'].toString())
        : null;
    final double diff = double.tryParse((s['diferencia'] ?? 0).toString()) ?? 0;

    final resumenVentas = s['resumen_ventas'] as List<dynamic>? ?? [];
    final desgloseEfectivo = s['desglose_efectivo'] as Map<String, dynamic>? ?? {};

    // Total de ventas en la sesión
    double totalVentas = 0;
    for (final m in resumenVentas) {
      totalVentas += double.tryParse((m['total'] ?? 0).toString()) ?? 0;
    }

    final diffColor = diff == 0
        ? Colors.green.shade700
        : (diff > 0 ? Colors.blue.shade700 : Colors.red.shade700);

    final String diffBadgeText = isAbierta
        ? "EN CURSO"
        : (diff == 0
            ? "CUADRADA (RD\$ 0.00)"
            : (diff > 0
                ? "SOBRANTE (+${FormatterNumber.formatCurrency(diff)})"
                : "FALTANTE (${FormatterNumber.formatCurrency(diff)})"));

    final int facturasCount = s['facturas_count'] != null
        ? int.tryParse(s['facturas_count'].toString()) ?? 0
        : (s['facturas'] is List ? (s['facturas'] as List).length : 0);

    return Container(
      color: const Color(0xFFF8F9FA),
      child: Column(
        children: [
          // ── ENCABEZADO SUPERIOR DEL DETALLE ──────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.azulOscuro.withValues(alpha: 0.1),
                  child: const Icon(
                    Icons.point_of_sale_rounded,
                    size: 22,
                    color: AppColors.azulOscuro,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          Text(
                            "Sesión de Caja #${s['id']} — ${s['caja']?['nombre'] ?? 'Caja'}",
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.azulOscuro,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2.5,
                            ),
                            decoration: BoxDecoration(
                              color: isAbierta
                                  ? Colors.green.withValues(alpha: 0.1)
                                  : Colors.grey.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isAbierta
                                    ? Colors.green.shade400
                                    : Colors.grey.shade400,
                              ),
                            ),
                            child: Text(
                              isAbierta ? "ABIERTA" : "CERRADA",
                              style: TextStyle(
                                color: isAbierta
                                    ? Colors.green.shade800
                                    : Colors.grey.shade800,
                                fontWeight: FontWeight.bold,
                                fontSize: 9.5,
                              ),
                            ),
                          ),
                          if (!isAbierta)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2.5,
                              ),
                              decoration: BoxDecoration(
                                color: diffColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: diffColor.withValues(alpha: 0.5),
                                ),
                              ),
                              child: Text(
                                diffBadgeText,
                                style: TextStyle(
                                  color: diffColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 9.5,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        "Turno: ${s['turno']?['nombre'] ?? 'General'}  •  Cajero: ${s['usuario']?['name'] ?? 'N/A'}",
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                // Botón Imprimir Reporte
                OutlinedButton.icon(
                  onPressed: _isPrinting ? null : _imprimirReporte,
                  icon: _isPrinting
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.print_outlined, size: 16),
                  label: const Text("Imprimir Ticket"),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.azulOscuro,
                    side: const BorderSide(color: AppColors.azulOscuro),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ],
            ),
          ),

          // ── TARJETAS KPIS RÁPIDOS ─────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                _buildKpiCard(
                  title: "Fondo Inicial",
                  value: FormatterNumber.formatCurrency(montoInicial),
                  subtitle: "Apertura de turno",
                  icon: Icons.savings_outlined,
                  color: AppColors.azulOscuro,
                ),
                const SizedBox(width: 10),
                _buildKpiCard(
                  title: "Monto Esperado",
                  value: FormatterNumber.formatCurrency(montoEsperado),
                  subtitle: "Inicial + Cobros Efec.",
                  icon: Icons.calculate_outlined,
                  color: Colors.blue.shade700,
                ),
                const SizedBox(width: 10),
                _buildKpiCard(
                  title: "Monto Físico",
                  value: montoFisico != null
                      ? FormatterNumber.formatCurrency(montoFisico)
                      : "Pendiente",
                  subtitle: "Conteo arqueo caja",
                  icon: Icons.payments_outlined,
                  color: Colors.teal.shade700,
                ),
                const SizedBox(width: 10),
                _buildKpiCard(
                  title: "Diferencia",
                  value: isAbierta ? "En curso" : FormatterNumber.formatCurrency(diff),
                  subtitle: isAbierta
                      ? "Cierre pendiente"
                      : (diff == 0 ? "Sin descuadre" : (diff > 0 ? "A favor" : "Faltante")),
                  icon: Icons.balance_outlined,
                  color: isAbierta ? Colors.grey.shade700 : diffColor,
                ),
              ],
            ),
          ),

          // ── TABS SELECTOR (Detalle Completo vs Facturas) ───────────────────────
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: TabBar(
              controller: _tabController,
              labelColor: AppColors.azulOscuro,
              unselectedLabelColor: Colors.grey,
              indicatorColor: AppColors.azulOscuro,
              indicatorWeight: 2.5,
              onTap: (index) {
                if (index == 1 && !_facturasLoaded) {
                  _loadFacturas();
                }
              },
              tabs: [
                const Tab(
                  icon: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.analytics_outlined, size: 16),
                      SizedBox(width: 6),
                      Text("Auditoría & Arqueo Financiero", style: TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
                Tab(
                  icon: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.receipt_long_outlined, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        facturasCount > 0
                            ? "Facturas Emitidas ($facturasCount)"
                            : "Facturas Emitidas",
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── CONTENIDO DE LAS PESTAÑAS ──────────────────────────────────────────
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // PESTAÑA 1: AUDITORÍA FINANCIERA & ARQUEO COMPLETO
                _buildTabAuditoriaFinanciera(
                  s,
                  isAbierta,
                  montoInicial,
                  montoEsperado,
                  montoFisico,
                  diff,
                  diffColor,
                  resumenVentas,
                  desgloseEfectivo,
                  totalVentas,
                  facturasCount,
                ),

                // PESTAÑA 2: LISTA DE FACTURAS EMITIDAS EN LA SESIÓN
                _buildTabFacturas(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabAuditoriaFinanciera(
    Map<String, dynamic> s,
    bool isAbierta,
    double montoInicial,
    double montoEsperado,
    double? montoFisico,
    double diff,
    Color diffColor,
    List<dynamic> resumenVentas,
    Map<String, dynamic> desgloseEfectivo,
    double totalVentas,
    int facturasCount,
  ) {
    final aperturaStr = s['fecha_apertura'] != null
        ? FormatterNumber.formatFechaHora(DateTime.parse(s['fecha_apertura']))
        : 'N/A';
    final cierreStr = s['fecha_cierre'] != null
        ? FormatterNumber.formatFechaHora(DateTime.parse(s['fecha_cierre']))
        : 'Pendiente (En curso)';
    final duracionStr = _calcularDuracion(s['fecha_apertura'], s['fecha_cierre']);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // COLUMNA IZQUIERDA
          Expanded(
            flex: 5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Información General
                _buildCardSection(
                  title: "Información de la Sesión y Turno",
                  icon: Icons.info_outline,
                  child: Column(
                    children: [
                      _buildInfoItem(Icons.person_outline, "Cajero Responsable", s['usuario']?['name'] ?? 'N/A'),
                      _buildInfoItem(Icons.point_of_sale, "Caja Física", s['caja']?['nombre'] ?? 'N/A'),
                      _buildInfoItem(Icons.schedule, "Turno de Trabajo", s['turno']?['nombre'] ?? 'N/A'),
                      _buildInfoItem(Icons.login_rounded, "Fecha y Hora Apertura", aperturaStr),
                      _buildInfoItem(Icons.logout_rounded, "Fecha y Hora Cierre", cierreStr),
                      _buildInfoItem(Icons.timelapse, "Duración de la Sesión", duracionStr),
                      _buildInfoItem(
                        Icons.receipt_outlined,
                        "Facturas Generadas",
                        "$facturasCount facturas registradas",
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // 2. Observaciones y Comentarios del Cierre
                _buildCardSection(
                  title: "Observaciones del Cajero",
                  icon: Icons.notes_rounded,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.amber.shade200),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.comment_outlined, size: 16, color: Colors.amber.shade800),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            (s['comentario'] != null && s['comentario'].toString().trim().isNotEmpty)
                                ? s['comentario'].toString()
                                : "Sin observaciones o notas registradas para este cierre.",
                            style: TextStyle(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                              color: Colors.amber.shade900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // COLUMNA DERECHA
          Expanded(
            flex: 6,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 3. Resumen de Ventas por Método de Pago
                _buildCardSection(
                  title: "Resumen de Cobros por Método",
                  icon: Icons.credit_card_outlined,
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Text(
                      "Total Ventas: ${FormatterNumber.formatCurrency(totalVentas)}",
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade800,
                      ),
                    ),
                  ),
                  child: resumenVentas.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            "No se registraron ventas en esta sesión.",
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                          ),
                        )
                      : Column(
                          children: resumenVentas.map((m) {
                            final String metodo = (m['metodo_pago'] ?? 'N/A').toString().toUpperCase();
                            final double total = double.tryParse((m['total'] ?? 0).toString()) ?? 0;
                            final double pct = totalVentas > 0 ? (total / totalVentas) : 0.0;

                            IconData mIcon = Icons.payment;
                            Color mColor = Colors.blue;
                            if (metodo.contains('EFECTIVO')) {
                              mIcon = Icons.money;
                              mColor = Colors.green;
                            } else if (metodo.contains('TARJETA')) {
                              mIcon = Icons.credit_card;
                              mColor = Colors.indigo;
                            } else if (metodo.contains('TRANSFERENCIA')) {
                              mIcon = Icons.account_balance;
                              mColor = Colors.deepOrange;
                            }

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Icon(mIcon, size: 16, color: mColor),
                                      const SizedBox(width: 8),
                                      Text(
                                        metodo,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                      const Spacer(),
                                      Text(
                                        FormatterNumber.formatCurrency(total),
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                          color: mColor,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        "(${(pct * 100).toStringAsFixed(1)}%)",
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.grey.shade500,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  LinearProgressIndicator(
                                    value: pct.clamp(0.0, 1.0),
                                    backgroundColor: Colors.grey.shade200,
                                    color: mColor,
                                    minHeight: 4,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                ),
                const SizedBox(height: 12),

                // 4. Desglose de Efectivo (Arqueo Físico de Billetes y Monedas)
                _buildCardSection(
                  title: "Desglose de Efectivo (Arqueo Físico)",
                  icon: Icons.monetization_on_outlined,
                  trailing: montoFisico != null
                      ? Text(
                          "Total: ${FormatterNumber.formatCurrency(montoFisico)}",
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.teal.shade800,
                          ),
                        )
                      : null,
                  child: isAbierta
                      ? Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline, size: 16, color: Colors.blue.shade800),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  "Esta caja aún se encuentra ABIERTA. El arqueo físico se registra al momento de realizar el cierre.",
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.blue.shade900,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      : desgloseEfectivo.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Text(
                                "No se registró desglose de billetes en este cierre.",
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                              ),
                            )
                          : Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: desgloseEfectivo.entries.map((entry) {
                                final denom = entry.key;
                                final cant = int.tryParse(entry.value.toString()) ?? 0;
                                final valNominal = double.tryParse(denom) ?? 0;
                                final subtotal = valNominal * cant;
                                final bool hasCount = cant > 0;

                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: hasCount
                                        ? Colors.teal.withValues(alpha: 0.08)
                                        : Colors.grey.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: hasCount
                                          ? Colors.teal.shade300
                                          : Colors.grey.shade200,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        "RD\$ $denom",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11,
                                          color: hasCount ? Colors.teal.shade900 : Colors.grey.shade600,
                                        ),
                                      ),
                                      Text(
                                        "x $cant = ${FormatterNumber.formatCurrency(subtotal)}",
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: hasCount ? Colors.teal.shade700 : Colors.grey.shade400,
                                          fontWeight: hasCount ? FontWeight.bold : FontWeight.normal,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabFacturas() {
    if (_isLoadingFacturas) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(strokeWidth: 2),
            SizedBox(height: 10),
            Text("Cargando facturas de la sesión...", style: TextStyle(fontSize: 12)),
          ],
        ),
      );
    }

    if (_facturas.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_outlined, size: 50, color: Colors.grey.shade300),
            const SizedBox(height: 10),
            Text(
              "No hay facturas asociadas a esta sesión de caja.",
              style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _loadFacturas,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text("Reintentar"),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: _facturas.length,
      separatorBuilder: (_, _) => const SizedBox(height: 6),
      itemBuilder: (context, idx) {
        final f = _facturas[idx];
        final total = double.tryParse((f['total'] ?? 0).toString()) ?? 0;
        final estado = (f['estado'] ?? 'emitida').toString().toUpperCase();
        final ncf = f['ncf'] ?? 'Sin NCF';
        final cliente = f['cliente']?['nombre'] ?? 'Consumidor Final';
        final fecha = f['fecha_emision'] != null
            ? FormatterNumber.formatFechaHora(DateTime.parse(f['fecha_emision']))
            : 'N/A';

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.azulOscuro.withValues(alpha: 0.08),
                child: Text(
                  "#${f['id']}",
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppColors.azulOscuro,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          "NCF: $ncf",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: AppColors.azulOscuro,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: estado == 'CANCELADA'
                                ? Colors.red.shade50
                                : Colors.green.shade50,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: estado == 'CANCELADA'
                                  ? Colors.red.shade300
                                  : Colors.green.shade300,
                            ),
                          ),
                          child: Text(
                            estado,
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: estado == 'CANCELADA'
                                  ? Colors.red.shade800
                                  : Colors.green.shade800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "Cliente: $cliente  •  $fecha",
                      style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              Text(
                FormatterNumber.formatCurrency(total),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: AppColors.azulOscuro,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCardSection({
    required String title,
    required IconData icon,
    required Widget child,
    Widget? trailing,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: AppColors.azulOscuro),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: AppColors.azulOscuro,
                  ),
                ),
              ),
              ?trailing,
            ],
          ),
          const Divider(height: 16),
          child,
        ],
      ),
    );
  }
}
