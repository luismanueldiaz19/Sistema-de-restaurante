// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'nomina_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(Nomina)
final nominaProvider = NominaProvider._();

final class NominaProvider extends $NotifierProvider<Nomina, NominaState> {
  NominaProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'nominaProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$nominaHash();

  @$internal
  @override
  Nomina create() => Nomina();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(NominaState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<NominaState>(value),
    );
  }
}

String _$nominaHash() => r'6fba16498caee2efcc2f87d5bd41c732b4142673';

abstract class _$Nomina extends $Notifier<NominaState> {
  NominaState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<NominaState, NominaState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<NominaState, NominaState>,
              NominaState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
