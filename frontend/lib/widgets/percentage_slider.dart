import 'package:flutter/material.dart';
import '../palletes/app_colors.dart';

class PercentageSlider extends StatelessWidget {
  final double totalValue;
  final TextEditingController amountController;
  final String label;

  const PercentageSlider({
    super.key,
    required this.totalValue,
    required this.amountController,
    this.label = 'Ajuste rápido',
  });

  @override
  Widget build(BuildContext context) {
    if (totalValue <= 0) return const SizedBox.shrink();

    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: amountController,
      builder: (context, value, child) {
        final currentAmount = double.tryParse(value.text) ?? 0.0;
        final pct = (currentAmount / totalValue * 100).clamp(0.0, 100.0);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
                Text(
                  '${pct.round()}%',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 4,
                activeTrackColor: AppColors.primary,
                inactiveTrackColor: Colors.orange.shade100,
                thumbColor: AppColors.primary,
                overlayColor: AppColors.primary.withValues(alpha: 0.1),
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
              ),
              child: Slider(
                value: pct,
                min: 0,
                max: 100,
                divisions: 10,
                label: '${pct.round()}%',
                onChanged: (val) {
                  final newMonto = totalValue * (val / 100);
                  amountController.text = newMonto.toStringAsFixed(2);
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
