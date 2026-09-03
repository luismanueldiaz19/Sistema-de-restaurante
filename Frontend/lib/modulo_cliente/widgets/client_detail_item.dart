import 'package:flutter/material.dart';

import '../../palletes/app_colors.dart';

class ClientDetailItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isHighlight;

  const ClientDetailItem({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.isHighlight = false,
  });

  @override
  State<ClientDetailItem> createState() => _ClientDetailItemState();
}

class _ClientDetailItemState extends State<ClientDetailItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _isHovered ? Colors.white : const Color(0xFFF9FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _isHovered
                ? AppColors.azulOscuro.withValues(alpha: 0.3)
                : Colors.black.withValues(alpha: 0.03),
            width: 1,
          ),
          boxShadow: [
            if (_isHovered)
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 15,
                offset: const Offset(0, 5),
              )
            else
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: widget.isHighlight
                    ? Colors.green.withValues(alpha: 0.1)
                    : _isHovered
                    ? AppColors.azulOscuro.withValues(alpha: 0.1)
                    : AppColors.azulOscuro.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(
                widget.icon,
                color: widget.isHighlight ? Colors.green : AppColors.azulOscuro,
                size: 20,
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.label,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.value,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: widget.isHighlight ? 16 : 14,
                      color: widget.isHighlight
                          ? Colors.green.shade700
                          : Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
