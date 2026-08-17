import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../palletes/app_colors.dart';
import '../models/metodo_pago.dart';
import '../providers/metodo_pago_provider.dart';

class PagoDialog extends ConsumerStatefulWidget {
  final double total;

  const PagoDialog({super.key, required this.total});

  @override
  ConsumerState<PagoDialog> createState() => _PagoDialogState();
}

class _PagoDialogState extends ConsumerState<PagoDialog> {
  final TextEditingController _montoController = TextEditingController();
  MetodoPago? _metodoPagoSeleccionado;
  double _montoRecibido = 0;

  @override
  void initState() {
    super.initState();
    _montoController.text = widget.total.toStringAsFixed(2);
    _montoRecibido = widget.total;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(metodoPagoProvider).fetchMetodosActivos().then((_) {
        final prov = ref.read(metodoPagoProvider);
        if (prov.metodos.isNotEmpty) {
          setState(() {
            _metodoPagoSeleccionado = prov.metodos.first;
          });
        }
      });
    });
  }

  double get _devuelta =>
      (_montoRecibido - widget.total) > 0 ? _montoRecibido - widget.total : 0;

  @override
  Widget build(BuildContext context) {
    final metodoProv = ref.watch(metodoPagoProvider);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        width: 500,
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
              
              if (metodoProv.isLoading)
                const Center(child: CircularProgressIndicator())
              else if (metodoProv.metodos.isEmpty)
                const Text('No hay métodos de pago configurados', style: TextStyle(color: Colors.red))
              else
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: metodoProv.metodos.map((metodo) {
                    IconData icon = Icons.payments_rounded;
                    if (metodo.tipo == 'tarjeta') icon = Icons.credit_card_rounded;
                    if (metodo.tipo == 'transferencia') icon = Icons.account_balance_rounded;

                    return SizedBox(
                      width: 140,
                      child: _buildMetodoBtn(metodo, icon, metodo.nombre),
                    );
                  }).toList(),
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

              if (_metodoPagoSeleccionado?.tipo == 'efectivo') ...[
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
                      (_montoRecibido < widget.total && _metodoPagoSeleccionado?.tipo == 'efectivo') || _metodoPagoSeleccionado == null
                      ? null
                      : () {
                          Navigator.pop(context, {
                            'monto_pagado': widget.total,
                            'monto_recibido': _montoRecibido,
                            'devuelta': _devuelta,
                            'metodo_pago': _metodoPagoSeleccionado?.tipo,
                            'metodo_pago_id': _metodoPagoSeleccionado?.id,
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

  Widget _buildMetodoBtn(MetodoPago metodo, IconData icon, String label) {
    bool isSelected = _metodoPagoSeleccionado?.id == metodo.id;
    return InkWell(
      onTap: () => setState(() => _metodoPagoSeleccionado = metodo),
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
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey.shade700,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
