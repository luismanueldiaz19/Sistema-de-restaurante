import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../model/banco_models.dart';
import '../../palletes/app_colors.dart';

class BankAccountCard extends StatefulWidget {
  final BankAccountModel account;
  final VoidCallback onTap;
  final VoidCallback? onEdit;

  const BankAccountCard({
    super.key,
    required this.account,
    required this.onTap,
    this.onEdit,
  });

  @override
  State<BankAccountCard> createState() => _BankAccountCardState();
}

class _BankAccountCardState extends State<BankAccountCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final formatCurrency = NumberFormat.currency(locale: 'en_US', symbol: '\$');
    final formattedBalance = formatCurrency.format(widget.account.currentBalance);
    // Separar el símbolo del número para estilizarlos distinto
    final parts = formattedBalance.split('\$');
    final numberPart = parts.length > 1 ? parts[1] : formattedBalance;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _isHovered ? 1.02 : 1.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutBack,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(_isHovered ? 0.08 : 0.03),
                  blurRadius: _isHovered ? 15 : 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Fila superior: Icono y Chip de estado
                Row(
                  children: [
                    Icon(
                      Icons.account_balance,
                      color: AppColors.primary,
                      size: 32,
                    ),
                    const Spacer(),
                    if (widget.onEdit != null)
                      IconButton(
                        icon: const Icon(Icons.edit, size: 20),
                        color: Colors.grey.shade600,
                        onPressed: widget.onEdit,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: widget.account.isActive ? Colors.green.shade50 : Colors.red.shade50,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        widget.account.isActive ? 'Activa' : 'Inactiva',
                        style: TextStyle(
                          color: widget.account.isActive ? Colors.green.shade700 : Colors.red.shade700,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Sección media: Nombres y número de cuenta
                Text(
                  widget.account.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xFF1F2937),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  widget.account.bank?.name ?? 'Banco Desconocido',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '# ${widget.account.accountNumber}',
                  style: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 13,
                  ),
                ),
                
                const Spacer(),
                Divider(color: Colors.grey.shade200, height: 16),
                
                // Sección inferior: Balance
                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 3, right: 4),
                        child: Text(
                          '\$',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Text(
                        numberPart,
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
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
        ),
      ),
    );
  }
}
