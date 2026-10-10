import 'package:flutter/material.dart';
import '../../models/proveedor.dart';
import '../../../palletes/app_colors.dart';
import '../../../../utils/get_initials.dart';

class ProveedorListCard extends StatelessWidget {
  final Proveedor proveedor;
  final bool isSelected;
  final VoidCallback onTap;
  final void Function(String action, Proveedor proveedor)? onMenuSelected;
  final bool canEdit;
  final bool canDelete;

  const ProveedorListCard({
    super.key,
    required this.proveedor,
    required this.isSelected,
    required this.onTap,
    this.onMenuSelected,
    this.canEdit = true,
    this.canDelete = true,
  });

  Color _getCardColor(String? name) {
    if (name == null || name.trim().isEmpty) return Colors.grey;
    final colors = [
      Colors.pink.shade400,
      Colors.blue.shade400,
      Colors.green.shade400,
      Colors.amber.shade400,
      Colors.purple.shade400,
      Colors.teal.shade400,
      Colors.indigo.shade400,
      Colors.deepOrange.shade400,
      Colors.lightBlue.shade400,
    ];
    final hash = name.codeUnits.fold(0, (prev, curr) => prev + curr);
    return colors[hash % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final cardColor = _getCardColor(proveedor.nombre);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected ? cardColor.withValues(alpha: 0.05) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? cardColor : Colors.transparent,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: IntrinsicHeight(
            child: Row(
              children: [
                // Línea de color izquierda
                Container(width: 5, color: cardColor),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: cardColor,
                          radius: 18,
                          child: Text(
                            InitialsHelper.getInitials(proveedor.nombre, defaultChar: "P"),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                proveedor.nombre,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: AppColors.primary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.phone,
                                    size: 12,
                                    color: Colors.green,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      (proveedor.telefono != null &&
                                              proveedor.telefono!.isNotEmpty)
                                          ? proveedor.telefono!
                                          : "----",
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey.shade600,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              if (proveedor.rnc != null &&
                                  proveedor.rnc!.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.badge_outlined,
                                      size: 12,
                                      color: Colors.grey,
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        'RNC: ${proveedor.rnc!}',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.grey.shade500,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                        // Opciones de menú
                        if (canEdit || canDelete)
                          PopupMenuButton<String>(
                            icon: const Icon(
                              Icons.more_vert,
                              color: Colors.grey,
                              size: 16,
                            ),
                            onSelected: (value) {
                              if (onMenuSelected != null) {
                                onMenuSelected!(value, proveedor);
                              }
                            },
                            itemBuilder: (BuildContext context) => [
                              if (canEdit)
                                const PopupMenuItem<String>(
                                  value: 'edit',
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.edit,
                                        size: 16,
                                        color: Colors.blue,
                                      ),
                                      SizedBox(width: 8),
                                      Text('Editar'),
                                    ],
                                  ),
                                ),
                              if (canDelete)
                                const PopupMenuItem<String>(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.delete,
                                        size: 16,
                                        color: Colors.red,
                                      ),
                                      SizedBox(width: 8),
                                      Text('Eliminar'),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
