import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../model/banco_models.dart';
import '../../palletes/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/bank_provider.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_button.dart';

class BankReconciliationScreen extends ConsumerStatefulWidget {
  final BankAccountModel account;

  const BankReconciliationScreen({super.key, required this.account});

  @override
  ConsumerState<BankReconciliationScreen> createState() => _BankReconciliationScreenState();
}

class _BankReconciliationScreenState extends ConsumerState<BankReconciliationScreen> {
  final Set<int> _selectedTransactions = {};
  final TextEditingController _saldoBancoCtrl = TextEditingController(text: '');
  DateTime _fechaCorte = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final token = ref.read(authProvider).token;
      if (token != null) {
        ref.read(bankProvider.notifier).loadTransactions(token, widget.account.id);
      }
    });
    _saldoBancoCtrl.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _saldoBancoCtrl.dispose();
    super.dispose();
  }

  void _completarConciliacion() async {
    if (_selectedTransactions.isEmpty) return;

    final token = ref.read(authProvider).token;
    if (token == null) return;

    try {
      await ref.read(bankProvider.notifier).reconcileTransactions(token, _selectedTransactions.toList());
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Conciliación completada exitosamente', style: TextStyle(color: Colors.white)), backgroundColor: Colors.green),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}', style: const TextStyle(color: Colors.white)), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(bankProvider);
    
    // Filtrar transacciones que no estén completadas
    final transactions = state.transactions.where((tx) {
      final s = tx.status.toLowerCase();
      return tx.bankAccountId == widget.account.id && s != 'completed' && s != 'completado';
    }).toList();

    final currentAccount = state.accounts.firstWhere(
      (acc) => acc.id == widget.account.id, 
      orElse: () => widget.account
    );
    
    final saldoLibros = currentAccount.currentBalance;
    
    double saldoConciliado = 0;
    for (var tx in transactions) {
      if (_selectedTransactions.contains(tx.id)) {
        final isPositive = tx.type == 'deposit' || tx.type == 'interest';
        saldoConciliado += isPositive ? tx.amount : -tx.amount;
      }
    }

    final saldoBanco = double.tryParse(_saldoBancoCtrl.text) ?? 0;
    final diferencia = saldoConciliado - saldoBanco;

    final formatCurrency = NumberFormat.currency(locale: 'en_US', symbol: '\$');

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Conciliación Bancaria', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
            Text(
              'Cuenta: ${currentAccount.name} (${currentAccount.accountNumber})', 
              style: const TextStyle(fontSize: 13, color: Colors.grey)
            ),
          ],
        ),
        backgroundColor: const Color(0xFFF3F4F6),
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Panel Izquierdo: Lista de Transacciones
            Expanded(
              flex: 5,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))
                  ],
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Transacciones Pendientes',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Marca (✓) las transacciones que aparecen en tu estado de cuenta del banco.',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(height: 24),
                    Expanded(
                      child: state.isLoading && transactions.isEmpty
                          ? const Center(child: CircularProgressIndicator())
                          : transactions.isEmpty
                              ? const Center(child: Text('No hay transacciones pendientes por conciliar', style: TextStyle(color: Colors.grey)))
                              : ListView.separated(
                                  itemCount: transactions.length,
                                  separatorBuilder: (context, index) => Divider(color: Colors.grey.shade200),
                                  itemBuilder: (context, index) {
                                    final tx = transactions[index];
                                    final isPositive = tx.type == 'deposit' || tx.type == 'interest';
                                    final color = isPositive ? Colors.green.shade700 : const Color(0xFFDC2626);
                                    final amountText = formatCurrency.format(tx.amount);
                                    final isSelected = _selectedTransactions.contains(tx.id);

                                    return InkWell(
                                      onTap: () {
                                        setState(() {
                                          if (isSelected) {
                                            _selectedTransactions.remove(tx.id);
                                          } else {
                                            _selectedTransactions.add(tx.id);
                                          }
                                        });
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        child: Row(
                                          children: [
                                            SizedBox(
                                              width: 120,
                                              child: Text(
                                                amountText,
                                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: color),
                                              ),
                                            ),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    (tx.description ?? 'Transacción').toUpperCase(),
                                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1F2937)),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    '${DateFormat('dd/MM/yyyy').format(DateTime.parse(tx.date))}${tx.reference != null && tx.reference!.isNotEmpty ? ' • Ref: ${tx.reference}' : ''}',
                                                    style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Checkbox(
                                              value: isSelected,
                                              onChanged: (val) {
                                                setState(() {
                                                  if (val == true) {
                                                    _selectedTransactions.add(tx.id);
                                                  } else {
                                                    _selectedTransactions.remove(tx.id);
                                                  }
                                                });
                                              },
                                              activeColor: const Color(0xFF1E3A8A),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
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
            ),
            
            const SizedBox(width: 24),
            
            // Panel Derecho: Resumen
            Expanded(
              flex: 3,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))
                  ],
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Datos del Banco',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: _saldoBancoCtrl,
                      label: '',
                      hintText: 'Saldo Final (según el Banco)',
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))],
                    ),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _fechaCorte,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (date != null) {
                          setState(() => _fechaCorte = date);
                        }
                      },
                      child: AbsorbPointer(
                        child: CustomTextField(
                          controller: TextEditingController(text: DateFormat('dd/MM/yyyy').format(_fechaCorte)),
                          label: 'Fecha de Corte',
                          readOnly: true,
                          suffixIcon: Icons.calendar_today,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 24),
                    
                    const Text(
                      'Resumen',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
                    ),
                    const SizedBox(height: 16),
                    
                    _buildSummaryRow('Saldo en Libros', formatCurrency.format(saldoLibros), Colors.grey.shade500, Colors.black),
                    const SizedBox(height: 12),
                    _buildSummaryRow('Saldo Conciliado', formatCurrency.format(saldoConciliado), Colors.grey.shade500, Colors.black),
                    const SizedBox(height: 12),
                    _buildSummaryRow('Saldo Banco', formatCurrency.format(saldoBanco), Colors.grey.shade500, Colors.black),
                    
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 24),
                    
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: diferencia == 0 ? Colors.green.shade50 : const Color(0xFFFEE2E2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: diferencia == 0 ? Colors.green.shade200 : const Color(0xFFFCA5A5)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Dif',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: diferencia == 0 ? Colors.green.shade700 : const Color(0xFFDC2626),
                            ),
                          ),
                          Text(
                            formatCurrency.format(diferencia),
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: diferencia == 0 ? Colors.green.shade700 : const Color(0xFFDC2626),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const Spacer(),
                    CustomButton(
                      title: 'Completar Conciliación',
                      onPressed: diferencia == 0 ? _completarConciliacion : null,
                      backgroundColor: diferencia == 0 ? AppColors.primary : Colors.grey.shade300,
                      foregroundColor: diferencia == 0 ? Colors.white : Colors.grey.shade500,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, Color labelColor, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: labelColor, fontSize: 14)),
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: valueColor, fontSize: 14)),
      ],
    );
  }
}
