import 'package:flutter/material.dart';
import '../palletes/app_colors.dart';

class CustomDateRangePicker extends StatelessWidget {
  final String tooltipMessage;
  final bool isPersonalizado;
  final Function(DateTime start, DateTime end) onDateRangeSelected;
  final double height;
  final double? width;
  final String? text;

  const CustomDateRangePicker({
    super.key,
    this.tooltipMessage = 'Rango de fechas',
    required this.isPersonalizado,
    required this.onDateRangeSelected,
    this.height = 40,
    this.width = 40,
    this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltipMessage,
      child: InkWell(
        onTap: () async {
          final range = await showDateRangePicker(
            context: context,
            firstDate: DateTime(2020),
            lastDate: DateTime(2030),
            builder: (context, child) {
              return Theme(
                data: Theme.of(context).copyWith(
                  colorScheme: const ColorScheme.light(
                    primary: AppColors.primary,
                    onPrimary: Colors.white,
                    surface: Colors.white,
                    onSurface: Colors.black87,
                  ),
                  datePickerTheme: DatePickerThemeData(
                    backgroundColor: Colors.white,
                    headerBackgroundColor: AppColors.primary,
                    headerForegroundColor: Colors.white,
                    rangeSelectionBackgroundColor: AppColors.primary.withValues(
                      alpha: 0.1,
                    ),
                    rangePickerBackgroundColor: Colors.white,
                    dayBackgroundColor: WidgetStateProperty.resolveWith((
                      states,
                    ) {
                      if (states.contains(WidgetState.selected)) {
                        return AppColors.primary;
                      }
                      return null;
                    }),
                    dayForegroundColor: WidgetStateProperty.resolveWith((
                      states,
                    ) {
                      if (states.contains(WidgetState.selected)) {
                        return Colors.white;
                      }
                      return Colors.black87;
                    }),
                  ),
                ),
                child: Dialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.0),
                  ),
                  insetPadding: const EdgeInsets.all(16.0),
                  clipBehavior: Clip.antiAlias,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: 400.0,
                      maxHeight: 500.0,
                    ),
                    child: child!,
                  ),
                ),
              );
            },
          );
          if (range != null) {
            onDateRangeSelected(range.start, range.end);
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: height,
          width: width,
          padding: text != null ? const EdgeInsets.symmetric(horizontal: 12) : null,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isPersonalizado
                ? AppColors.primary.withValues(alpha: 0.1)
                : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isPersonalizado ? AppColors.primary : Colors.grey.shade300,
            ),
          ),
          child: text != null
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.calendar_month_outlined,
                      color: isPersonalizado ? AppColors.primary : Colors.grey.shade600,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        text!,
                        style: TextStyle(
                          fontSize: 12,
                          color: isPersonalizado ? AppColors.primary : Colors.grey.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                )
              : Icon(
                  Icons.calendar_month_outlined,
                  color: isPersonalizado ? AppColors.primary : Colors.grey.shade600,
                  size: 18,
                ),
        ),
      ),
    );
  }
}
