import 'package:flutter/material.dart';

class CustomFilterDropdown<T> extends StatelessWidget {
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  final double height;
  final EdgeInsetsGeometry padding;
  final BorderRadius? borderRadius;
  final double fontSize;

  const CustomFilterDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    this.height = 40,
    this.padding = const EdgeInsets.symmetric(horizontal: 12),
    this.borderRadius,
    this.fontSize = 12,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: borderRadius ?? BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          icon: const Icon(Icons.arrow_drop_down, size: 18),
          style: TextStyle(
            fontSize: fontSize,
            color: Colors.grey.shade700,
            fontWeight: FontWeight.bold,
          ),
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }
}
