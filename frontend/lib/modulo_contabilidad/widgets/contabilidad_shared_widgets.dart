import 'package:flutter/material.dart';
import '../../palletes/app_colors.dart';
import '../../utils/formatter_number.dart';

class ContabilidadKpiChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final String? badge;

  const ContabilidadKpiChip({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.09),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          color: color,
                        ),
                      ),
                    ),
                    if (badge != null) ...[
                      const SizedBox(width: 5),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1.5,
                        ),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          badge!,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: color,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 1),
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

class ContabilidadDateButton extends StatelessWidget {
  final String prefix;
  final DateTime? date;
  final String emptyLabel;
  final VoidCallback onTap;

  const ContabilidadDateButton({
    super.key,
    required this.prefix,
    required this.date,
    required this.onTap,
    this.emptyLabel = 'Seleccionar',
  });

  @override
  Widget build(BuildContext context) {
    final text = date != null
        ? '$prefix: ${FormatterNumber.formatFechaLatina(date!)}'
        : '$prefix: $emptyLabel';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: date != null
                ? AppColors.azulOscuro.withValues(alpha: 0.25)
                : Colors.grey.shade300,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.calendar_today_rounded,
              size: 13.5,
              color: AppColors.azulOscuro,
            ),
            const SizedBox(width: 6),
            Text(
              text,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: AppColors.azulOscuro,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ContabilidadQuickPresetChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const ContabilidadQuickPresetChip({
    super.key,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(7),
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 9),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
      ),
    );
  }
}

class ContabilidadTableHeaderText extends StatelessWidget {
  final String text;
  final TextAlign textAlign;

  const ContabilidadTableHeaderText(
    this.text, {
    super.key,
    this.textAlign = TextAlign.left,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: textAlign,
      style: TextStyle(
        fontSize: 10.5,
        fontWeight: FontWeight.w800,
        color: Colors.grey.shade700,
      ),
    );
  }
}

class ContabilidadSummaryBar extends StatelessWidget {
  final String title;
  final String? subtitle;
  final double amount;
  final Color backgroundColor;
  final Color foregroundColor;

  const ContabilidadSummaryBar({
    super.key,
    required this.title,
    required this.amount,
    this.subtitle,
    this.backgroundColor = AppColors.azulOscuro,
    this.foregroundColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: foregroundColor,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: 10.5,
                      color: foregroundColor.withValues(alpha: 0.78),
                    ),
                  ),
              ],
            ),
          ),
          Text(
            FormatterNumber.formatCurrency(amount),
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w900,
              fontFamily: 'Consolas',
              color: foregroundColor,
            ),
          ),
        ],
      ),
    );
  }
}

