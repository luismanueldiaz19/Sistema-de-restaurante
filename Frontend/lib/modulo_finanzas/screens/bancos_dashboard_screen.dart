import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../palletes/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/bank_provider.dart';
import 'bank_transactions_screen.dart';
import '../widgets/bank_account_dialog.dart';
import '../widgets/bank_account_card.dart';

class BancosDashboardScreen extends ConsumerStatefulWidget {
  const BancosDashboardScreen({super.key});

  @override
  ConsumerState<BancosDashboardScreen> createState() =>
      _BancosDashboardScreenState();
}

class _BancosDashboardScreenState extends ConsumerState<BancosDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final token = ref.read(authProvider).token;
      if (token != null) {
        ref.read(bankProvider.notifier).loadDashboardData(token);
      }
    });
  }

  void _abrirDialogoNuevaCuenta() {
    showDialog(context: context, builder: (ctx) => const BankAccountDialog());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(bankProvider);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Bancos y Cuentas'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: state.isLoading && state.accounts.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : state.errorMessage != null && state.accounts.isEmpty
          ? Center(child: Text('Error: ${state.errorMessage}'))
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Gestionar los saldos y conciliaciones de cuentas',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 360,
                            childAspectRatio: 1.25,
                            crossAxisSpacing: 20,
                            mainAxisSpacing: 20,
                          ),
                      itemCount: state.accounts.length,
                      itemBuilder: (context, index) {
                        final cuenta = state.accounts[index];
                        return BankAccountCard(
                          account: cuenta,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    BankTransactionsScreen(account: cuenta),
                              ),
                            );
                          },
                          onEdit: () {
                            showDialog(
                              context: context,
                              builder: (ctx) => BankAccountDialog(account: cuenta),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _abrirDialogoNuevaCuenta,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Nueva Cuenta',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}
