import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../model/factura.dart';
import '../repositories/repo_factura.dart';
import 'factura_state.dart';

part 'factura_provider.g.dart';

@riverpod
class FacturaNotifier extends _$FacturaNotifier {
  final FacturaRepository _repo = FacturaRepository();

  @override
  FacturaState build() {
    return FacturaState();
  }

  Future<void> crearFactura(Factura factura, String token) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _repo.crearFactura(factura, token);
      state = state.copyWith(
        facturaId: response['factura_id'],
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
    }
  }
}
