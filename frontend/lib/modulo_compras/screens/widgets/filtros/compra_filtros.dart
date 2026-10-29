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
    const filters = ['Todos', 'Hoy', 'Ayer', 'Este Mes'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Fila 1: Buscador y Filtro de Estado
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 36,
                child: TextField(
                  controller: searchCtrl,
                  style: const TextStyle(fontSize: 12.5),
                  decoration: InputDecoration(
                    hintText: 'Buscar factura, proveedor o NCF...',
                    hintStyle: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade400,
                    ),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      size: 18,
                      color: Colors.grey.shade500,
                    ),
                    prefixIconConstraints: const BoxConstraints(
                      minWidth: 34,
                      minHeight: 34,
                    ),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: AppColors.primary,
                        width: 1.5,
                      ),
                    ),
                  ),
                  onSubmitted: onSearchSubmitted,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              height: 36,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: selectedStatus,
                  icon: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 18,
                    color: Colors.grey.shade600,
                  ),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.secondary,
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'todos',
                      child: Text('Todos los Estados'),
                    ),
                    DropdownMenuItem(
                      value: 'PENDIENTE',
                      child: Text('Pendiente'),
                    ),
                    DropdownMenuItem(
                      value: 'PAGADA',
                      child: Text('Pagada'),
                    ),
                    DropdownMenuItem(
                      value: 'ANULADA',
                      child: Text('Anulada'),
                    ),
                  ],
                  onChanged: onStatusChanged,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        // Fila 2: Chips Compactos de Fecha
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              ...filters.map((filter) {
                final isSelected = selectedDateFilter == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 6.0),
                  child: InkWell(
                    onTap: () => onDateFilterSelected(filter),
                    borderRadius: BorderRadius.circular(6),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary
                            : Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : Colors.grey.shade300,
                          width: 1,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.25,
                                  ),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ]
                            : null,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isSelected) ...[
                            const Icon(
                              Icons.check_rounded,
                              size: 13,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 4),
                          ],
                          Text(
                            filter,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                              color: isSelected
                                  ? Colors.white
                                  : Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
              CustomDateRangePicker(
                text: 'Rango...',
                isPersonalizado: selectedDateFilter == 'Rango...',
                height: 28,
                width: 85,
                onDateRangeSelected: onDateRangeSelected,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
