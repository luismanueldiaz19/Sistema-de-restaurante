// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cliente_admin_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ClienteAdmin)
final clienteAdminProvider = ClienteAdminProvider._();

final class ClienteAdminProvider
    extends $NotifierProvider<ClienteAdmin, ClienteAdminState> {
  ClienteAdminProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'clienteAdminProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$clienteAdminHash();

  @$internal
  @override
  ClienteAdmin create() => ClienteAdmin();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ClienteAdminState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ClienteAdminState>(value),
    );
  }
}

String _$clienteAdminHash() => r'43631b09aac31e8ef4334cb2bf77b490c16f6c35';

abstract class _$ClienteAdmin extends $Notifier<ClienteAdminState> {
  ClienteAdminState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<ClienteAdminState, ClienteAdminState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ClienteAdminState, ClienteAdminState>,
              ClienteAdminState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
