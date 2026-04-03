import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../palletes/app_colors.dart';

class HeaderFacturacion extends StatelessWidget {
  final String nombreSistema;
  final double montoCaja;
  final bool cajaAbierta;
  final String usuario;
  final DateTime fecha;
  final VoidCallback? onMenuTap;

  const HeaderFacturacion({
    super.key,
    required this.nombreSistema,
    required this.montoCaja,
    required this.cajaAbierta,
    required this.usuario,
    required this.fecha,
    this.onMenuTap,
  });

  @override
  Widget build(BuildContext context) {
    final fechaFormat = DateFormat('dd/MM/yyyy').format(fecha);

    final style = Theme.of(context).textTheme;
    Shader linearGradient = const LinearGradient(
      colors: <Color>[
        // AppColors.azulClaro,
        AppColors.error, AppColors.azulOscuro,
      ],
    ).createShader(const Rect.fromLTWH(50.0, 50.0, 200.0, 125.0));

    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.grisClaro,
        border: const Border(bottom: BorderSide(color: Colors.black12)),
      ),
      child: Row(
        children: [
          // 🔹 Sistema
          Row(
            children: [
              const Icon(Icons.settings, size: 22, color: AppColors.azulOscuro),
              const SizedBox(width: 8),
              Text(
                nombreSistema,
                style: style.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  foreground: Paint()..shader = linearGradient,
                ),
              ),
            ],
          ),

          const Spacer(),

          // // 💰 Caja
          // _InfoItem(
          //   icon: Icons.attach_money,
          //   label: cajaAbierta ? 'Caja Abierta' : 'Caja Cerrada',
          //   value: NumberFormat.currency(
          //     locale: 'es_DO',
          //     symbol: '\$',
          //   ).format(montoCaja),
          //   color: cajaAbierta ? Colors.green : Colors.red,
          // ),

          // const SizedBox(width: 25),

          // // 👤 Usuario
          // _InfoItem(icon: Icons.person, label: 'Usuario', value: usuario),

          // const SizedBox(width: 25),

          // // 📅 Fecha
          // _InfoItem(
          //   icon: Icons.calendar_today,
          //   label: 'Fecha',
          //   value: fechaFormat,
          // ),

          // const SizedBox(width: 25),

          // ☰ Menú
          IconButton(icon: const Icon(Icons.menu), onPressed: onMenuTap),
        ],
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? color;

  const _InfoItem({
    required this.icon,
    required this.label,
    required this.value,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme;
    return Row(
      children: [
        Icon(icon, size: 18, color: color ?? Colors.black54),
        const SizedBox(width: 6),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: style.headlineSmall?.copyWith(
                fontSize: 11,
                color: Colors.black54,
              ),
            ),
            Text(
              value,
              style: style.labelSmall?.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: color ?? Colors.black87,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
