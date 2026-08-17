class BankModel {
  final int id;
  final String name;
  final String? code;
  final bool isActive;

  BankModel({
    required this.id,
    required this.name,
    this.code,
    required this.isActive,
  });

  factory BankModel.fromJson(Map<String, dynamic> json) {
    return BankModel(
      id: json['id'],
      name: json['name'],
      code: json['code'],
      isActive: json['is_active'] == 1 || json['is_active'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'is_active': isActive,
    };
  }
}

class BankAccountModel {
  final int id;
  final int bankId;
  final String name;
  final String accountNumber;
  final String currency;
  final double currentBalance;
  final int? accountingAccountId;
  final bool isActive;
  final BankModel? bank;

  BankAccountModel({
    required this.id,
    required this.bankId,
    required this.name,
    required this.accountNumber,
    required this.currency,
    required this.currentBalance,
    this.accountingAccountId,
    required this.isActive,
    this.bank,
  });

  factory BankAccountModel.fromJson(Map<String, dynamic> json) {
    return BankAccountModel(
      id: json['id'],
      bankId: json['bank_id'],
      name: json['name'],
      accountNumber: json['account_number'],
      currency: json['currency'] ?? 'DOP',
      currentBalance: double.tryParse(json['current_balance']?.toString() ?? '0') ?? 0.0,
      accountingAccountId: json['accounting_account_id'],
      isActive: json['is_active'] == 1 || json['is_active'] == true,
      bank: json['bank'] != null ? BankModel.fromJson(json['bank']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bank_id': bankId,
      'name': name,
      'account_number': accountNumber,
      'currency': currency,
      'current_balance': currentBalance,
      'accounting_account_id': accountingAccountId,
      'is_active': isActive,
    };
  }
}

class BankTransactionModel {
  final int id;
  final int bankAccountId;
  final String date;
  final String type;
  final double amount;
  final String? reference;
  final String? description;
  final String status;
  final BankAccountModel? bankAccount;

  BankTransactionModel({
    required this.id,
    required this.bankAccountId,
    required this.date,
    required this.type,
    required this.amount,
    this.reference,
    this.description,
    required this.status,
    this.bankAccount,
  });

  factory BankTransactionModel.fromJson(Map<String, dynamic> json) {
    return BankTransactionModel(
      id: json['id'],
      bankAccountId: json['bank_account_id'],
      date: json['date'],
      type: json['type'],
      amount: double.tryParse(json['amount']?.toString() ?? '0') ?? 0.0,
      reference: json['reference'],
      description: json['description'],
      status: json['status'],
      bankAccount: json['bank_account'] != null ? BankAccountModel.fromJson(json['bank_account']) : null,
    );
  }
}
