import '../models/cliente.dart';

class ClienteAdminState {
  final bool isLoading;
  final List<Cliente> clientes;
  final String? error;
  final int currentPage;
  final int totalPages;

  ClienteAdminState({
    this.isLoading = false,
    this.clientes = const [],
    this.error,
    this.currentPage = 1,
    this.totalPages = 1,
  });

  ClienteAdminState copyWith({
    bool? isLoading,
    List<Cliente>? clientes,
    String? error,
    int? currentPage,
    int? totalPages,
  }) {
    return ClienteAdminState(
      isLoading: isLoading ?? this.isLoading,
      clientes: clientes ?? this.clientes,
      error: error ?? this.error,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
    );
  }
}
