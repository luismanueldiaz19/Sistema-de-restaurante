import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/compra.dart';
import '../../../utils/helpers.dart';
import '../../../utils/constants.dart';
import '../../../palletes/app_colors.dart';
import 'pagos_compra_dialog.dart';

class CompraDetallePanel extends StatelessWidget {
  final Compra? compra;
  final bool isLoading;

  const CompraDetallePanel({
    super.key,
    required this.compra,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Container(
        decoration: _panelDecoration(),
        child: const Center(
          child: CircularProgressIndicator(
            color: AppColors.primary,
            strokeWidth: 2,
          ),
        ),
      );
    }

    if (compra == null) {
      return Container(
        decoration: _panelDecoration(),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.receipt_long_outlined,
                size: 40,
                color: Colors.grey.shade300,
              ),
              const SizedBox(height: 10),
              Text(
                'Selecciona una compra',
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'Los detalles aparecerán aquí',
                style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: _panelDecoration(),
      child: Column(
        children: [
          // 1. CABECERA MODERNA Y COMPACTA
          _buildHeader(context),

          // 2. METADATOS EN GRID COMPACTO
          _buildMetadataCard(),

          // 3. TABLA DE ARTÍCULOS COMPRADOS
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Artículos comprados',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 1.5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEF2F6),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${compra!.detalles.length}',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF475569),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Contenedor tipo tabla empresarial
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        children: [
                          // Encabezados fijos de tabla
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 7,
                            ),
                            color: const Color(0xFFF1F5F9),
                            child: const Row(
                              children: [
                                SizedBox(width: 36),
                                Expanded(
                                  flex: 4,
                                  child: Text(
                                    'PRODUCTO',
                                    style: TextStyle(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF475569),
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    'PRECIO',
                                    textAlign: TextAlign.right,
                                    style: TextStyle(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF475569),
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    'ITBIS',
                                    textAlign: TextAlign.right,
                                    style: TextStyle(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF475569),
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    'TOTAL',
                                    textAlign: TextAlign.right,
                                    style: TextStyle(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF475569),
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Divider(
                            height: 1,
                            thickness: 1,
                            color: Color(0xFFE2E8F0),
                          ),

                          // Filas de artículos
                          Expanded(
                            child: compra!.detalles.isEmpty
                                ? Center(
                                    child: Text(
                                      'No hay artículos registrados',
                                      style: TextStyle(
                                        color: Colors.grey.shade400,
                                        fontSize: 11.5,
                                      ),
                                    ),
                                  )
                                : ListView.separated(
                                    padding: EdgeInsets.zero,
                                    itemCount: compra!.detalles.length,
                                    separatorBuilder: (_, _) => const Divider(
                                      height: 1,
                                      thickness: 1,
                                      color: Color(0xFFF1F5F9),
                                    ),
                                    itemBuilder: (context, index) {
                                      final item = compra!.detalles[index];
                                      final isEven = index % 2 == 0;
                                      return Container(
                                        color: isEven
                                            ? Colors.white
                                            : const Color(0xFFFAFAFB),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 7,
                                        ),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            // Cantidad pill
                                            Container(
                                              width: 28,
                                              height: 22,
                                              alignment: Alignment.center,
                                              decoration: BoxDecoration(
                                                color: AppColors.primary
                                                    .withValues(alpha: 0.1),
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                '${item.cantidad % 1 == 0 ? item.cantidad.toInt() : item.cantidad}x',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w800,
                                                  fontSize: 10.5,
                                                  color: AppColors.primary,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),

                                            // Nombre producto
                                            Expanded(
                                              flex: 4,
                                              child: Text(
                                                item.producto?.nombre ??
                                                    item.descripcion ??
                                                    'Desconocido',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 11.5,
                                                  color: Color(0xFF1E293B),
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),

                                            // Precio
                                            Expanded(
                                              flex: 2,
                                              child: Text(
                                                FormatterNumber.formatCurrency(
                                                  item.costoUnitario,
                                                ),
                                                style: const TextStyle(
                                                  color: Color(0xFF475569),
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                                textAlign: TextAlign.right,
                                              ),
                                            ),

                                            // ITBIS
                                            Expanded(
                                              flex: 2,
                                              child: Text(
                                                FormatterNumber.formatCurrency(
                                                  item.impuestoMonto,
                                                ),
                                                style: const TextStyle(
                                                  color: Color(0xFF64748B),
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                                textAlign: TextAlign.right,
                                              ),
                                            ),

                                            // Total
                                            Expanded(
                                              flex: 2,
                                              child: Text(
                                                FormatterNumber.formatCurrency(
                                                  item.total,
                                                ),
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 11.5,
                                                  color: Color(0xFF0F172A),
                                                ),
                                                textAlign: TextAlign.right,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Notas (si existen)
                  if (compra!.notas != null &&
                      compra!.notas!.trim().isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFBEB),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFFDE68A)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.notes_rounded,
                            color: Color(0xFFD97706),
                            size: 14,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: RichText(
                              text: TextSpan(
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF92400E),
                                ),
                                children: [
                                  const TextSpan(
                                    text: 'Notas: ',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  TextSpan(text: compra!.notas!),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 8),

          // 4. TOTALES RESUMEN
          _buildFooterTotales(),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        borderRadius: BorderRadius.vertical(top: Radius.circular(11)),
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2F6),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: const Icon(
                  Icons.receipt_long_outlined,
                  size: 15,
                  color: Color(0xFF334155),
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'DETALLE DE COMPRA',
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4,
                    ),
                  ),
                  Text(
                    'Factura #${compra!.numeroFacturaProveedor}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
            ],
          ),
          Row(
            children: [
              if (compra!.estado != 'PENDIENTE')
                SizedBox(
                  height: 28,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => PagosCompraDialog(
                          compraId: compra!.id,
                          totalCompra: compra!.total,
                        ),
                      );
                    },
                    icon: const Icon(
                      Icons.history,
                      size: 13,
                      color: Colors.white,
                    ),
                    label: const Text(
                      'Ver Pagos',
                      style: TextStyle(
                        fontSize: 10.5,
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 0,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                ),
              const SizedBox(width: 6),
              SizedBox(
                height: 28,
                child: OutlinedButton.icon(
                  onPressed: () => _abrirPdfCompra(context),
                  icon: const Icon(
                    Icons.picture_as_pdf_outlined,
                    size: 13,
                    color: AppColors.primary,
                  ),
                  label: const Text(
                    'PDF',
                    style: TextStyle(
                      fontSize: 10.5,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: AppColors.primary.withValues(alpha: 0.5),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 0,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              _buildEstadoBadge(compra!.estado),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _abrirPdfCompra(BuildContext context) async {
    final pdfUrl = compra?.pdfUrl;
    if (pdfUrl != null && pdfUrl.isNotEmpty) {
      final url = Uri.parse('$hostName$pdfUrl');
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
        return;
      }
    }
    if (compra != null) {
      final fallbackUrl =
          Uri.parse('$hostName/api/v2/compras/${compra!.id}/pdf');
      if (await canLaunchUrl(fallbackUrl)) {
        await launchUrl(fallbackUrl, mode: LaunchMode.externalApplication);
        return;
      }
    }
    if (context.mounted) {
      showToast(context, 'No se pudo abrir el PDF');
    }
  }

  Widget _buildEstadoBadge(String estado) {
    Color bg;
    Color border;
    Color text;
    Color dot;

    switch (estado.toUpperCase()) {
      case 'PAGADA':
        bg = const Color(0xFFECFDF5);
        border = const Color(0xFFA7F3D0);
        text = const Color(0xFF065F46);
        dot = const Color(0xFF10B981);
        break;
      case 'PENDIENTE':
        bg = const Color(0xFFFFFBEB);
        border = const Color(0xFFFDE68A);
        text = const Color(0xFF92400E);
        dot = const Color(0xFFF59E0B);
        break;
      case 'ANULADA':
        bg = const Color(0xFFFEF2F2);
        border = const Color(0xFFFECACA);
        text = const Color(0xFF991B1B);
        dot = const Color(0xFFEF4444);
        break;
      default:
        bg = const Color(0xFFF1F5F9);
        border = const Color(0xFFE2E8F0);
        text = const Color(0xFF475569);
        dot = const Color(0xFF94A3B8);
    }

    return Container(
      height: 26,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            estado.toUpperCase(),
            style: TextStyle(
              color: text,
              fontWeight: FontWeight.w700,
              fontSize: 10.5,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetadataCard() {
    final bool hasVencimiento =
        compra!.fechaVencimiento != null && compra!.tipoCompra == 'CREDITO';

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                flex: 4,
                child: _buildInfoCell(
                  'PROVEEDOR',
                  compra!.proveedor?.nombre ?? 'Desconocido',
                  Icons.business_outlined,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 3,
                child: _buildInfoCell(
                  'NCF / COMPROBANTE',
                  compra!.ncf?.isNotEmpty == true ? compra!.ncf! : 'N/A',
                  Icons.receipt_outlined,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 3,
                child: _buildInfoCell(
                  'TIPO PAGO',
                  compra!.tipoCompra,
                  Icons.credit_card_outlined,
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 6),
            child: Divider(height: 1, thickness: 1, color: Color(0xFFEDF2F7)),
          ),
          Row(
            children: [
              Expanded(
                flex: 4,
                child: _buildInfoCell(
                  'FECHA EMISIÓN',
                  compra!.fechaCompra.toString().split(' ')[0],
                  Icons.calendar_today_outlined,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 3,
                child: _buildInfoCell(
                  'REGISTRADO POR',
                  compra!.usuario?.name ?? 'Administrador',
                  Icons.person_outline,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 3,
                child: hasVencimiento
                    ? _buildInfoCell(
                        'VENCE',
                        compra!.fechaVencimiento.toString().split(' ')[0],
                        Icons.event_busy_outlined,
                      )
                    : _buildInfoCell(
                        'ARTÍCULOS',
                        '${compra!.detalles.length} ${compra!.detalles.length == 1 ? 'ítem' : 'ítems'}',
                        Icons.inventory_2_outlined,
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCell(String label, String value, IconData icon) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(5),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Icon(icon, size: 12, color: const Color(0xFF475569)),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 8.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 1),
              Tooltip(
                message: value,
                child: Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 11.5,
                    color: Color(0xFF0F172A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFooterTotales() {
    final hasTaxOrSubtotal = compra!.impuestos > 0 || compra!.subtotal > 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(11)),
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Column(
        children: [
          if (hasTaxOrSubtotal) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Subtotal',
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  FormatterNumber.formatCurrency(compra!.subtotal),
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF334155),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 3),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Impuestos (ITBIS)',
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  FormatterNumber.formatCurrency(compra!.impuestos),
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF334155),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 5),
              child: Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0)),
            ),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 3,
                    height: 14,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'TOTAL DE COMPRA',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                      letterSpacing: 0.3,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              Text(
                FormatterNumber.formatCurrency(compra!.total),
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 17,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  BoxDecoration _panelDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFE2E8F0)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.03),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }
}
