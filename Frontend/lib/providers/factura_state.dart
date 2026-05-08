class FacturaState {
  final bool isLoading;
  final String? error;
  final int? facturaId;

  FacturaState({
    this.isLoading = false,
    this.error,
    this.facturaId,
  });

  FacturaState copyWith({
    bool? isLoading,
    String? error,
    int? facturaId,
  }) {
    return FacturaState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      facturaId: facturaId ?? this.facturaId,
    );
  }
}
