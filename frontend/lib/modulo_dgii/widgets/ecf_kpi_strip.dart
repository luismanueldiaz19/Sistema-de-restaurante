import 'package:flutter/material.dart';
import '../../palletes/app_colors.dart';
import '../models/ecf_models.dart';

class EcfKpiStrip extends StatelessWidget {
  final EcfConfigModel config;
  final EcfCertificadoMeta certificado;
  final Map<String, int> estadisticas;
  final VoidCallback onOpenConfig;

  const EcfKpiStrip({
    super.key,
    required this.config,
    required this.certificado,
    required this.estadisticas,
    required this.onOpenConfig,
  });

  @override
  Widget build(BuildContext context) {
    final total = estadisticas['total'] ?? 0;
    final aceptados = estadisticas['aceptados'] ?? 0;
    final pendientes =
        (estadisticas['en_proceso'] ?? 0) + (estadisticas['pendientes'] ?? 0);
    final rechazados = estadisticas['rechazados'] ?? 0;

    return Row(
      children: [
        Expanded(
          flex: 3,
          child: InkWell(
            onTap: onOpenConfig,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: certificado.valido
                      ? Colors.teal.shade200
                      : Colors.orange.shade300,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: certificado.valido
                          ? Colors.teal.shade50
                          : Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      certificado.valido
                          ? Icons.verified_user_rounded
                          : Icons.warning_amber_rounded,
                      size: 18,
                      color: certificado.valido
                          ? Colors.teal.shade700
                          : Colors.orange.shade800,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          config.razonSocial.isEmpty
                              ? 'Emisor no configurado'
                              : '${config.razonSocial} (RNC: ${config.rncEmisor})',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.azulOscuro,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          certificado.valido
                              ? 'Firma .p12 activa (${certificado.cn}) • ${certificado.diasRestantes} días vigentes'
                              : (certificado.error ??
                                    'Sin certificado .p12 válido instalado'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            color: certificado.valido
                                ? Colors.teal.shade700
                                : Colors.orange.shade800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.tune_rounded,
                    size: 16,
                    color: Colors.blueGrey,
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _MiniKpiCard(
            label: 'Total e-CF',
            value: total.toString(),
            icon: Icons.receipt_long_rounded,
            color: AppColors.azulOscuro,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _MiniKpiCard(
            label: 'Aceptados',
            value: aceptados.toString(),
            icon: Icons.check_circle_outline_rounded,
            color: Colors.teal.shade700,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _MiniKpiCard(
            label: 'En Proceso',
            value: pendientes.toString(),
            icon: Icons.schedule_rounded,
            color: Colors.orange.shade700,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _MiniKpiCard(
            label: 'Rechazados',
            value: rechazados.toString(),
            icon: Icons.error_outline_rounded,
            color: Colors.red.shade700,
          ),
        ),
      ],
    );
  }
}

class _MiniKpiCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _MiniKpiCard({
    required this.label,
    required this.value,
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
                  value,
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

