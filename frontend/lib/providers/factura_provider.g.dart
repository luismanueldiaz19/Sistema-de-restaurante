// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'factura_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(FacturaNotifier)
final facturaProvider = FacturaNotifierProvider._();

final class FacturaNotifierProvider
    extends $NotifierProvider<FacturaNotifier, FacturaState> {
  FacturaNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'facturaProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$facturaNotifierHash();

  @$internal
  @override
  FacturaNotifier create() => FacturaNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FacturaState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FacturaState>(value),
    );
  }
}

String _$facturaNotifierHash() => r'8042321d045f23759da411b80c5f15db3baa8d10';

abstract class _$FacturaNotifier extends $Notifier<FacturaState> {
  FacturaState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<FacturaState, FacturaState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<FacturaState, FacturaState>,
              FacturaState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
