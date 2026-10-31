import 'package:flutter_riverpod/legacy.dart';
import 'package:sistema_restaurante/model/banco_models.dart';
import 'package:sistema_restaurante/services/bank_service.dart';

class BankState {
  final bool isLoading;
  final String? errorMessage;
  final List<BankModel> banks;
  final List<BankAccountModel> accounts;
  final List<BankTransactionModel> transactions;

  BankState({
    this.isLoading = false,
    this.errorMessage,
    this.banks = const [],
    this.accounts = const [],
    this.transactions = const [],
  });

  BankState copyWith({
    bool? isLoading,
    String? errorMessage,
    List<BankModel>? banks,
    List<BankAccountModel>? accounts,
    List<BankTransactionModel>? transactions,
  }) {
    return BankState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      banks: banks ?? this.banks,
      accounts: accounts ?? this.accounts,
      transactions: transactions ?? this.transactions,
    );
  }
}

class BankNotifier extends StateNotifier<BankState> {
  final BankService _service = BankService();

  BankNotifier() : super(BankState());

  Future<void> loadDashboardData(String token) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final banks = await _service.getBanks(token: token);
      final accounts = await _service.getBankAccounts(token: token);
      
      state = state.copyWith(
        isLoading: false,
        banks: banks,
        accounts: accounts,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> createBank(String token, String name, String? code) async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);
      final newBank = await _service.createBank(token, {'name': name, 'code': code, 'is_active': true});
      state = state.copyWith(
        isLoading: false,
        banks: [...state.banks, newBank],
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      rethrow;
    }
  }

  Future<void> createAccount(String token, Map<String, dynamic> data) async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);
      final newAccount = await _service.createBankAccount(token, data);
      state = state.copyWith(
        isLoading: false,
        accounts: [...state.accounts, newAccount],
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      rethrow;
    }
  }

  Future<void> updateAccount(String token, int id, Map<String, dynamic> data) async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);
      final updatedAccount = await _service.updateBankAccount(token, id, data);
      state = state.copyWith(
        isLoading: false,
        accounts: state.accounts.map((acc) => acc.id == id ? updatedAccount : acc).toList(),
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      rethrow;
    }
  }

  Future<void> loadTransactions(String token, int accountId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final transactions = await _service.getBankTransactions(token: token, accountId: accountId);
      state = state.copyWith(
        isLoading: false,
        transactions: transactions,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> registerTransaction(String token, Map<String, dynamic> data) async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);
      final newTx = await _service.createBankTransaction(token, data);
      
      // Update account balance locally
      final updatedAccounts = state.accounts.map((acc) {
        if (acc.id == newTx.bankAccountId) {
          final balanceAdj = (newTx.type == 'withdrawal' || newTx.type == 'fee') ? -newTx.amount.abs() : newTx.amount.abs();
          return BankAccountModel(
            id: acc.id,
            bankId: acc.bankId,
            name: acc.name,
            accountNumber: acc.accountNumber,
            currency: acc.currency,
            currentBalance: acc.currentBalance + balanceAdj,
            accountingAccountId: acc.accountingAccountId,
            isActive: acc.isActive,
            bank: acc.bank,
          );
        }
        return acc;
      }).toList();

      state = state.copyWith(
        isLoading: false,
        transactions: [newTx, ...state.transactions],
        accounts: updatedAccounts,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      rethrow;
    }
  }

  Future<void> reconcileTransactions(String token, List<int> transactionIds) async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);
      await _service.reconcileBankTransactions(token, transactionIds);
      
      // Update local transactions state
      final updatedTransactions = state.transactions.map((tx) {
        if (transactionIds.contains(tx.id)) {
          return BankTransactionModel(
            id: tx.id,
            bankAccountId: tx.bankAccountId,
            date: tx.date,
            type: tx.type,
            amount: tx.amount,
            reference: tx.reference,
            description: tx.description,
            status: 'completed',
            bankAccount: tx.bankAccount,
          );
        }
        return tx;
      }).toList();

      state = state.copyWith(
        isLoading: false,
        transactions: updatedTransactions,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      rethrow;
    }
  }
}

final bankProvider = StateNotifierProvider<BankNotifier, BankState>((ref) {
  return BankNotifier();
});
