import 'package:flutter/material.dart';
import '../../palletes/app_colors.dart';
import '../../utils/formatter_number.dart';
import '../models/ecf_models.dart';

class EcfDocumentoRow extends StatelessWidget {
  final EcfDocumentoItem doc;
  final VoidCallback onViewXml;
  final VoidCallback onOpenQr;
  final VoidCallback onCheckStatus;
  final VoidCallback onResend;

  const EcfDocumentoRow({
    super.key,
    required this.doc,
    required this.onViewXml,
    required this.onOpenQr,
    required this.onCheckStatus,
    required this.onResend,
  });

  Color _statusColor(String estado) {
    final e = estado.toUpperCase();
    if (e.contains('ACEPTADO')) return Colors.teal.shade700;
    if (e.contains('PROCESO') || e == 'PENDIENTE') {
      return Colors.orange.shade800;
    }
    return Colors.red.shade700;
  }

  @override
  Widget build(BuildContext context) {
    final stColor = _statusColor(doc.estadoDgii);
    final comprador =
        (doc.razonSocialComprador != null &&
            doc.razonSocialComprador!.trim().isNotEmpty)
        ? doc.razonSocialComprador!
        : 'Consumidor Final';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      doc.encf,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppColors.azulOscuro,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blueGrey.shade50,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        doc.esResumenFc ? 'E${doc.tipoEcf} RFCE' : 'E${doc.tipoEcf}',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                          color: Colors.blueGrey.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${doc.fechaEmision} • ${doc.ambiente.toUpperCase()}',
                  style: TextStyle(fontSize: 10.5, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  comprador,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  (doc.rncComprador != null && doc.rncComprador!.isNotEmpty)
                      ? 'RNC/Céd: ${doc.rncComprador}'
                      : 'Sin RNC',
                  style: TextStyle(fontSize: 10.5, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.indigo.shade50,
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  doc.codigoSeguridad,
                  style: TextStyle(
                    fontFamily: 'Consolas',
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo.shade800,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  FormatterNumber.formatCurrency(doc.montoTotal),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.azulOscuro,
                  ),
                ),
                Text(
                  'ITBIS: ${FormatterNumber.formatCurrency(doc.totalItbis)}',
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Tooltip(
              message: doc.ultimoError ?? doc.trackId ?? doc.estadoDgii,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                decoration: BoxDecoration(
                  color: stColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: stColor.withValues(alpha: 0.25)),
                ),
                child: Text(
                  doc.estadoDgii,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: stColor,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 128,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                  tooltip: 'Ver XML Firmado y Validación',
                  icon: const Icon(Icons.code_rounded, size: 16),
                  color: AppColors.azulOscuro,
                  onPressed: onViewXml,
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                  tooltip: 'Abrir Timbre QR DGII',
                  icon: const Icon(Icons.qr_code_2_rounded, size: 16),
                  color: Colors.teal.shade700,
                  onPressed: onOpenQr,
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                  tooltip: 'Consultar Estado por TrackId',
                  icon: const Icon(Icons.sync_rounded, size: 16),
                  color: Colors.blue.shade700,
                  onPressed: doc.trackId == null ? null : onCheckStatus,
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                  tooltip: 'Reenviar Comprobante a DGII',
                  icon: const Icon(Icons.send_rounded, size: 15),
                  color: AppColors.primary,
                  onPressed: onResend,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

