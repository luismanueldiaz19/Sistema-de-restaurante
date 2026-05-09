import 'package:flutter/material.dart';
import '../../palletes/app_colors.dart';

class PagoDialog extends StatefulWidget {
  final double total;

  const PagoDialog({super.key, required this.total});

  @override
  State<PagoDialog> createState() => _PagoDialogState();
}

class _PagoDialogState extends State<PagoDialog> {
  final TextEditingController _montoController = TextEditingController();
  String _metodoPago = 'efectivo';
  double _montoRecibido = 0;

  @override
  void initState() {
    super.initState();
    _montoController.text = widget.total.toStringAsFixed(2);
    _montoRecibido = widget.total;
  }

  double get _devuelta =>
      (_montoRecibido - widget.total) > 0 ? _montoRecibido - widget.total : 0;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        width: 450,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 30,
              offset: const Offset(0, 15),
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Procesar Pago',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: AppColors.secondary,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded, color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Resumen de Total
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.1),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'TOTAL A COBRAR',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                        letterSpacing: 1,
                      ),
                    ),
                    Text(
                      '\$${widget.total.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              const Text(
                'MÉTODO DE PAGO',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildMetodoBtn(
                    'efectivo',
                    Icons.payments_rounded,
                    'Efectivo',
                  ),
                  const SizedBox(width: 12),
                  _buildMetodoBtn(
                    'tarjeta',
                    Icons.credit_card_rounded,
                    'Tarjeta',
                  ),
                  const SizedBox(width: 12),
                  _buildMetodoBtn(
                    'transferencia',
                    Icons.account_balance_rounded,
                    'Transf.',
                  ),
                ],
              ),
              const SizedBox(height: 32),

              const Text(
                'MONTO RECIBIDO',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _montoController,
                keyboardType: TextInputType.number,
                autofocus: true,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: AppColors.secondary,
                ),
                decoration: InputDecoration(
                  prefixText: '\$ ',
                  filled: true,
                  fillColor: AppColors.light,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 20,
                  ),
                ),
                onChanged: (v) {
                  setState(() {
                    _montoRecibido = double.tryParse(v) ?? 0;
                  });
                },
              ),

              if (_metodoPago == 'efectivo') ...[
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: _montoRecibido >= widget.total
                        ? Colors.green.withOpacity(0.05)
                        : Colors.orange.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'CAMBIO (DEVUELTA)',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: _montoRecibido >= widget.total
                              ? Colors.green
                              : Colors.orange,
                        ),
                      ),
                      Text(
                        '\$${_devuelta.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: _montoRecibido >= widget.total
                              ? Colors.green
                              : Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed:
                      _montoRecibido < widget.total && _metodoPago == 'efectivo'
                      ? null
                      : () {
                          Navigator.pop(context, {
                            'monto_pagado': widget.total,
                            'monto_recibido': _montoRecibido,
                            'devuelta': _devuelta,
                            'metodo_pago': _metodoPago,
                          });
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'FINALIZAR VENTA',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetodoBtn(String id, IconData icon, String label) {
    bool isSelected = _metodoPago == id;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _metodoPago = id),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : AppColors.light,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? AppColors.primary : Colors.grey.shade100,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : Colors.grey,
                size: 24,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey.shade700,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
