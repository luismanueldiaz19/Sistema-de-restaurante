import 'package:flutter/material.dart';

class HorizontalSelector<T> extends StatelessWidget {
  final List<T> items;
  final T? selectedItem;
  final String Function(T item) labelBuilder;
  final String Function(T item)? valueBuilder;
  final void Function(T item) onItemSelected;

  final Color selectedColor;
  final Color unselectedColor;
  final Color textSelectedColor;
  final Color textUnselectedColor;

  final Duration animationDuration;
  final Curve animationCurve;
  final double height;

  const HorizontalSelector({
    super.key,
    required this.items,
    required this.selectedItem,
    required this.labelBuilder,
    this.valueBuilder,
    required this.onItemSelected,
    this.selectedColor = Colors.brown,
    this.unselectedColor = Colors.white,
    this.textSelectedColor = Colors.white,
    this.textUnselectedColor = Colors.black54,
    this.animationDuration = const Duration(milliseconds: 300),
    this.animationCurve = Curves.easeInOut,
    this.height = 65,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final isSelected = item == selectedItem;
        return SizedBox(
          // height: height,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
            child: GestureDetector(
              onTap: () => onItemSelected(item),
              child: AnimatedContainer(
                duration: animationDuration,
                curve: animationCurve,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: isSelected ? selectedColor : unselectedColor,
                  borderRadius: BorderRadius.circular(5),
                  boxShadow: [
                    if (isSelected)
                      const BoxShadow(
                        color: Colors.black26,
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      )
                    else
                      const BoxShadow(
                        color: Colors.black12,
                        blurRadius: 4,
                        offset: Offset(1, 2),
                      ),
                  ],
                ),
                child: AnimatedDefaultTextStyle(
                  duration: animationDuration,
                  curve: animationCurve,
                  style: TextStyle(
                    color: isSelected ? textSelectedColor : textUnselectedColor,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: isSelected ? 16 : 14,
                  ),
                  child: Row(
                    children: [
                      Text(labelBuilder(item)),
                      if (valueBuilder != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          valueBuilder!(item),
                          style: TextStyle(
                            fontSize: 12,
                            color: isSelected
                                ? textSelectedColor.withOpacity(0.9)
                                : Colors.grey[600],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
