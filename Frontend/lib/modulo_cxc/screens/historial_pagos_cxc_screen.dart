import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../palletes/app_colors.dart';
import '../../utils/helpers.dart';
import '../models/pago_cxc.dart';
import '../providers/cxc_provider.dart';

class HistorialPagosCxcScreen extends ConsumerStatefulWidget {
  const HistorialPagosCxcScreen({super.key});

  @override
  ConsumerState<HistorialPagosCxcScreen> createState() =>
      _HistorialPagosCxcScreenState();
}

class _HistorialPagosCxcScreenState
    extends ConsumerState<HistorialPagosCxcScreen> {
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(cxcProvider.notifier).loadHistorialPagos(),
    );
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<PagoCxc> _filtrarPagos(List<PagoCxc> pagos) {
    final query = _searchCtrl.text.trim().toLowerCase();
    if (query.isEmpty) return pagos;

    return pagos.where((p) {
      final clienteNombre =
          (p.cuentaPorCobrar?['cliente']?['nombre'] ?? '').toString().toLowerCase();
      final ncf =
          (p.cuentaPorCobrar?['factura']?['ncf'] ?? '').toString().toLowerCase();
      final metodo = p.metodoPago.toLowerCase();
      final ref = (p.referencia ?? '').toLowerCase();

      return clienteNombre.contains(query) ||
          ncf.contains(query) ||
          metodo.contains(query) ||
          ref.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(cxcProvider);
    final listaFiltrada = _filtrarPagos(state.historialPagos);
    final totalRecaudado = state.historialPagos.fold(
      0.0,
      (sum, p) => sum + p.montoPagado,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Volver',
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Historial de Cobros',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
                letterSpacing: -0.2,
              ),
            ),
            Text(
              'Registro y comprobantes de abonos en cuentas por cobrar',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 20),
            onPressed: () =>
                ref.read(cxcProvider.notifier).loadHistorialPagos(),
            tooltip: 'Actualizar historial',
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFE2E8F0), height: 1),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Métricas resumidas compactas
            Row(
              children: [
                Expanded(
                  flex: 5,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
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
                          width: 36,
                          height: 36,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: const Color(0xFF059669)
                                .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.savings_outlined,
                            color: Color(0xFF059669),
                            size: 19,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'TOTAL RECAUDADO',
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF64748B),
                                  letterSpacing: 0.4,
                                ),
                              ),
                              const SizedBox(height: 1),
                              Text(
                                FormatterNumber.formatCurrency(totalRecaudado),
                                style: const TextStyle(
                                  fontSize: 16.5,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF059669),
                                  letterSpacing: -0.3,
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
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 3,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
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
                          width: 36,
                          height: 36,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppColors.azulOscuro.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.receipt_long_rounded,
                            color: AppColors.azulOscuro,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'TOTAL RECIBOS',
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF64748B),
                                  letterSpacing: 0.4,
                                ),
                              ),
                              const SizedBox(height: 1),
                              Text(
                                '${state.historialPagos.length} cobros',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Buscador
            Container(
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (_) => setState(() {}),
                style: const TextStyle(fontSize: 12),
                decoration: InputDecoration(
                  hintText: 'Buscar por cliente, NCF, método o referencia...',
                  hintStyle:
                      TextStyle(fontSize: 11.5, color: Colors.grey.shade400),
                  prefixIcon: const Icon(Icons.search,
                      size: 16, color: Color(0xFF64748B)),
                  suffixIcon: _searchCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 14),
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() {});
                          },
                        )
                      : null,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                  border: InputBorder.none,
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Listado de Recibos
            Expanded(
              child: state.isLoadingHistorial && state.historialPagos.isEmpty
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.azulOscuro,
                        strokeWidth: 2.5,
                      ),
                    )
                  : listaFiltrada.isEmpty
                      ? _buildEmptyState(state.historialPagos.isEmpty)
                      : ListView.separated(
                          itemCount: listaFiltrada.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final p = listaFiltrada[index];
                            return _buildPagoCard(p);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPagoCard(PagoCxc p) {
    final clienteNombre =
        p.cuentaPorCobrar?['cliente']?['nombre'] ?? 'Cliente General';
    final ncfFactura = p.cuentaPorCobrar?['factura']?['ncf'] ?? 'N/A';
    final bancoNombre = p.cuentaDestino?['bank']?['name'] ?? '';

    // Determinamos icono y color según método de pago
    IconData mIcon;
    Color mColor;
    switch (p.metodoPago.toLowerCase()) {
      case 'tarjeta':
        mIcon = Icons.credit_card_rounded;
        mColor = const Color(0xFF2563EB);
        break;
      case 'transferencia':
        mIcon = Icons.account_balance_rounded;
        mColor = const Color(0xFF7C3AED);
        break;
      case 'efectivo':
      default:
        mIcon = Icons.payments_rounded;
        mColor = const Color(0xFF059669);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.015),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Icono avatar
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFF059669).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.receipt_rounded,
              color: Color(0xFF059669),
              size: 18,
            ),
          ),
          const SizedBox(width: 12),

          // Datos principales
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      clienteNombre,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 12.5,
                        color: Color(0xFF0F172A),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Text(
                        'NCF: $ncfFactura',
                        style: const TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF475569),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    // Fecha
                    Icon(Icons.calendar_today_outlined,
                        size: 11, color: Colors.grey.shade500),
                    const SizedBox(width: 4),
                    Text(
                      p.fechaPago.split(' ')[0],
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Método de pago chip
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: mColor.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(4),
                        border:
                            Border.all(color: mColor.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(mIcon, size: 10, color: mColor),
                          const SizedBox(width: 4),
                          Text(
                            p.metodoPago.toUpperCase(),
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: mColor,
                            ),
                          ),
                        ],
                      ),
                    ),

                    if (bancoNombre.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Text(
                        '($bancoNombre)',
                        style: TextStyle(
                          fontSize: 10.5,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],

                    if (p.referencia != null && p.referencia!.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Text(
                          'Ref: ${p.referencia}',
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // Monto pagado
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                FormatterNumber.formatCurrency(p.montoPagado),
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                  color: Color(0xFF059669),
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 2),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                decoration: BoxDecoration(
                  color: const Color(0xFF059669).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: const Text(
                  'COBRADO',
                  style: TextStyle(
                    color: Color(0xFF059669),
                    fontSize: 8.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool noDataTotal) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(28),
        margin: const EdgeInsets.only(top: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.receipt_long_rounded,
                color: Color(0xFF64748B),
                size: 22,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              noDataTotal
                  ? 'No hay cobros registrados'
                  : 'No se encontraron resultados',
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 13,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              noDataTotal
                  ? 'Los abonos realizados a cuentas por cobrar aparecerán aquí.'
                  : 'Ningún recibo coincide con el término de búsqueda.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 11.5),
            ),
          ],
        ),
      ),
    );
  }
}
