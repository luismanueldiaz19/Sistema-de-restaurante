class RecetaState {
  final bool isLoading;
  final String? error;

  RecetaState({
    this.isLoading = false,
    this.error,
  });

  RecetaState copyWith({
    bool? isLoading,
    String? error,
  }) {
    return RecetaState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}
