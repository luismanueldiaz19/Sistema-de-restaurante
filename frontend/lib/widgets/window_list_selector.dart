import 'package:flutter/material.dart';

import '../utils/helpers.dart';

/// Dialog genérico estilo Windows para seleccionar un objeto de una lista.
/// [T] es el tipo de objeto que quieras manejar.
class WindowsSelectorDialog<T> extends StatefulWidget {
  final List<T> items;
  final String Function(T) labelBuilder; // cómo mostrar cada objeto
  final String? title; // título opcional

  const WindowsSelectorDialog({
    super.key,
    required this.items,
    required this.labelBuilder,
    this.title,
  });

  @override
  State<WindowsSelectorDialog<T>> createState() =>
      _WindowsSelectorDialogState<T>();
}

class _WindowsSelectorDialogState<T> extends State<WindowsSelectorDialog<T>> {
  String filter = "";

  @override
  Widget build(BuildContext context) {
    final filteredItems = widget.items
        .where(
          (item) => widget
              .labelBuilder(item)
              .toLowerCase()
              .contains(filter.toLowerCase()),
        )
        .toList();
    final style = Theme.of(context).textTheme;
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadiusGeometry.circular(0),
      ),
      backgroundColor: Colors.white,
      title: widget.title != null
          ? Text(
              widget.title!,
              style: style.titleMedium?.copyWith(color: Colors.black54),
            )
          : null,
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            textFieldWidgetUI(
              width: 400,
              label: 'Filtrar...',
              hintText: 'Filtrar...',
              onChanged: (value) {
                setState(() => filter = value);
              },
            ),

            // Campo de filtro
            const SizedBox(height: 12),
            Expanded(
              child: ListView.separated(
                itemCount: filteredItems.length,
                separatorBuilder: (_, __) =>
                    Divider(height: 1, color: Colors.grey[400]),
                itemBuilder: (context, index) {
                  final item = filteredItems[index];
                  return InkWell(
                    onTap: () => Navigator.of(context).pop(item),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.insert_drive_file, color: Colors.blueGrey),
                          const SizedBox(width: 8),
                          Text(
                            widget.labelBuilder(item),
                            style: const TextStyle(
                              fontFamily: 'Segoe UI',
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
