import 'package:flutter/material.dart';
import '../../../../palletes/app_colors.dart';
import '../../../../widgets/custom_date_range_picker.dart';

class CompraFiltros extends StatelessWidget {
  final TextEditingController searchCtrl;
  final String selectedStatus;
  final String selectedDateFilter;
  final Function(String) onSearchSubmitted;
  final Function(String?) onStatusChanged;
  final Function(String) onDateFilterSelected;
  final Function(DateTime, DateTime) onDateRangeSelected;

  const CompraFiltros({
    super.key,
    required this.searchCtrl,
    required this.selectedStatus,
    required this.selectedDateFilter,
    required this.onSearchSubmitted,
    required this.onStatusChanged,
    required this.onDateFilterSelected,
    required this.onDateRangeSelected,
  });

  @override
  Widget build(BuildContext context) {
    final filters = ['Todos', 'Hoy', 'Ayer', 'Este Mes'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: searchCtrl,
                decoration: InputDecoration(
                  hintText: 'Buscar factura, proveedor o NCF...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 0,
                  ),
                ),
                onSubmitted: onSearchSubmitted,
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: selectedStatus,
                  items: const [
                    DropdownMenuItem(
                      value: 'todos',
                      child: Text('Todos los Estados'),
                    ),
                    DropdownMenuItem(
                      value: 'PENDIENTE',
                      child: Text('Pendiente'),
                    ),
                    DropdownMenuItem(value: 'PAGADA', child: Text('Pagada')),
                    DropdownMenuItem(value: 'ANULADA', child: Text('Anulada')),
                  ],
                  onChanged: onStatusChanged,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              ...filters.map((filter) {
                final isSelected = selectedDateFilter == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Text(filter),
                    selected: isSelected,
                    onSelected: (bool selected) {
                      if (selected) {
                        onDateFilterSelected(filter);
                      }
                    },
                    selectedColor: AppColors.primary.withOpacity(0.2),
                    labelStyle: TextStyle(
                      color: isSelected
                          ? AppColors.primary
                          : Colors.grey.shade700,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isSelected
                            ? AppColors.primary
                            : Colors.grey.shade300,
                      ),
                    ),
                  ),
                );
              }),
              CustomDateRangePicker(
                text: 'Rango...',
                isPersonalizado: selectedDateFilter == 'Rango...',
                height: 32,
                width: 90,
                onDateRangeSelected: onDateRangeSelected,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
