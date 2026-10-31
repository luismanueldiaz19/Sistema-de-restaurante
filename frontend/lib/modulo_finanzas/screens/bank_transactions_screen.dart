import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../model/banco_models.dart';
import '../../palletes/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/bank_provider.dart';
import '../widgets/bank_transaction_dialog.dart';
import 'bank_reconciliation_screen.dart';
import '../../widgets/custom_button.dart';

class BankTransactionsScreen extends ConsumerStatefulWidget {
  final BankAccountModel account;

  const BankTransactionsScreen({super.key, required this.account});

  @override
  ConsumerState<BankTransactionsScreen> createState() => _BankTransactionsScreenState();
}

class _BankTransactionsScreenState extends ConsumerState<BankTransactionsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final token = ref.read(authProvider).token;
      if (token != null) {
        ref.read(bankProvider.notifier).loadTransactions(token, widget.account.id);
      }
    });
  }

  void _abrirDialogoNuevaTransaccion() {
    showDialog(
      context: context,
      builder: (ctx) => BankTransactionDialog(accountId: widget.account.id),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(bankProvider);
    final transactions = state.transactions.where((tx) => tx.bankAccountId == widget.account.id).toList();

    // Get the updated account balance from the provider if possible
    final currentAccount = state.accounts.firstWhere((acc) => acc.id == widget.account.id, orElse: () => widget.account);
    final headerFormat = NumberFormat.currency(locale: 'en_US', symbol: '');
    final formattedHeaderBalance = headerFormat.format(currentAccount.currentBalance);

    return Scaffold(
      appBar: AppBar(
        title: Text('Transacciones: ${currentAccount.name}'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0, top: 8.0, bottom: 8.0),
            child: CustomButton(
              title: 'Conciliar',
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => BankReconciliationScreen(account: currentAccount)));
              },
              width: null, // Allow button to size itself
              icon: Icons.fact_check,
            ),
          )
        ],
      ),
      backgroundColor: const Color(0xFFF3F4F6),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            width: double.infinity,
            color: Colors.white,
            child: Column(
              children: [
                const Text('Balance Actual', style: TextStyle(fontSize: 16, color: Colors.grey)),
                const SizedBox(height: 8),
                Text(
                  '${currentAccount.currency} \$$formattedHeaderBalance',
                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Transacciones Recientes',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: state.isLoading && transactions.isEmpty
                          ? const Center(child: CircularProgressIndicator())
                          : transactions.isEmpty
                              ? const Center(child: Text('No hay transacciones registradas', style: TextStyle(color: Colors.grey)))
                              : ListView.separated(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  itemCount: transactions.length,
                                  separatorBuilder: (context, index) => Divider(color: Colors.grey.shade100, height: 1),
                                  itemBuilder: (context, index) {
                                    final tx = transactions[index];
                                    final isPositive = tx.type == 'deposit' || tx.type == 'interest';
                                    
                                    // Colors and icons based on transaction type
                                    final color = isPositive ? Colors.green.shade700 : const Color(0xFFDC2626);
                                    final bgColor = isPositive ? Colors.green.shade50 : const Color(0xFFFEE2E2);
                                    final icon = isPositive ? Icons.arrow_downward : Icons.arrow_upward;

                                    // Amount formatting
                                    final formatCurrency = NumberFormat.currency(locale: 'en_US', symbol: '\$', decimalDigits: 2);
                                    final amountText = formatCurrency.format(tx.amount);

                                    // Status handling
                                    String statusText = tx.status;
                                    Color statusColor = const Color(0xFFD97706);
                                    Color statusBgColor = const Color(0xFFFEF3C7);

                                    if (tx.status.toLowerCase() == 'completed' || tx.status.toLowerCase() == 'completado') {
                                      statusText = 'Completado';
                                      statusColor = Colors.green.shade700;
                                      statusBgColor = Colors.green.shade50;
                                    } else if (tx.status.toLowerCase() == 'pending' || tx.status.toLowerCase() == 'en tránsito') {
                                      statusText = 'En Tránsito';
                                    }

                                    return Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 48,
                                            height: 48,
                                            decoration: BoxDecoration(
                                              color: bgColor,
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(icon, color: color, size: 20),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  (tx.description ?? 'Transacción').toUpperCase(),
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 15,
                                                    color: Color(0xFF1F2937),
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  '${DateFormat('dd/MM/yyyy').format(DateTime.parse(tx.date))}${tx.reference != null && tx.reference!.isNotEmpty ? ' • Ref: ${tx.reference}' : ''}',
                                                  style: const TextStyle(
                                                    color: Color(0xFF6B7280),
                                                    fontSize: 13,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.end,
                                            children: [
                                              Text(
                                                amountText,
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 15,
                                                  color: color,
                                                ),
                                              ),
                                              const SizedBox(height: 6),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: statusBgColor,
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                child: Text(
                                                  statusText.toUpperCase(),
                                                  style: TextStyle(
                                                    color: statusColor,
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _abrirDialogoNuevaTransaccion,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
