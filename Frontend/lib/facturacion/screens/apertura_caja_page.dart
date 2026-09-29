import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../palletes/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../utils/helpers.dart';
import '../../modulo_caja/providers/caja_provider.dart';
import '../../modulo_caja/models/caja_models.dart';
import '../../modulo_caja/services/caja_service.dart';

class AperturaCajaPage extends ConsumerStatefulWidget {
  const AperturaCajaPage({super.key});

  @override
  ConsumerState<AperturaCajaPage> createState() => _AperturaCajaPageState();
}

class _AperturaCajaPageState extends ConsumerState<AperturaCajaPage> {
  final _montoController = TextEditingController(text: '0.00');
  final _service = CajaService();

  Caja? _cajaSeleccionada;
  Turno? _turnoSeleccionado;
  List<Caja> _cajas = [];
  List<Turno> _turnos = [];
  bool _loadingData = true;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final token = ref.read(authProvider).token!;
    try {
      final cajasData = await _service.getCajas(token);
      final turnosData = await _service.getTurnos(token);

      final cajas = cajasData.map((e) => Caja.fromJson(e)).toList();
      final turnos = turnosData.map((e) => Turno.fromJson(e)).toList();

      setState(() {
        _cajas = cajas;
        _turnos = turnos;
        if (cajas.isNotEmpty) _cajaSeleccionada = cajas.first;
        if (turnos.isNotEmpty) _turnoSeleccionado = turnos.first;
        _loadingData = false;
      });
    } catch (e) {
      setState(() => _loadingData = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cajaState = ref.watch(cajaProvider);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: Center(
        child: Container(
          width: 320,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(
                Icons.account_balance_wallet_rounded,
                size: 48,
                color: AppColors.primary,
              ),
              const SizedBox(height: 12),
              const Text(
                'APERTURA DE CAJA',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: AppColors.azulOscuro,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Inicia tu jornada laboral registrando el monto base.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 11),
              ),
              const SizedBox(height: 16),

              if (_loadingData)
                const CircularProgressIndicator()
              else ...[
                // Selector de Caja
                _buildDropdown<Caja>(
                  label: 'Seleccionar Caja',
                  value: _cajaSeleccionada,
                  items: _cajas
                      .map(
                        (c) =>
                            DropdownMenuItem(value: c, child: Text(c.nombre)),
                      )
                      .toList(),
                  onChanged: (val) => setState(() => _cajaSeleccionada = val),
                  icon: Icons.storefront_rounded,
                ),
                const SizedBox(height: 16),

                // Selector de Turno
                _buildDropdown<Turno>(
                  label: 'Seleccionar Turno',
                  value: _turnoSeleccionado,
                  items: _turnos
                      .map(
                        (t) =>
                            DropdownMenuItem(value: t, child: Text(t.nombre)),
                      )
                      .toList(),
                  onChanged: (val) => setState(() => _turnoSeleccionado = val),
                  icon: Icons.access_time_rounded,
                ),
                const SizedBox(height: 16),

                // Monto Inicial
                TextFormField(
                  controller: _montoController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Monto Inicial (Fondo de Caja)',
                    hintText: '0.00',
                    labelStyle: const TextStyle(fontSize: 12),
                    prefixIcon: const Icon(
                      Icons.account_balance_wallet_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  height: 40,
                  child: ElevatedButton(
                    onPressed: cajaState.isLoading ? null : _confirmarApertura,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 4,
                    ),
                    child: cajaState.isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'ABRIR CAJA Y EMPEZAR',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 4),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'VOLVER ATRÁS',
                    style: TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required Function(T?) onChanged,
    required IconData icon,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      items: items,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 12),
        prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        isDense: true,
      ),
    );
  }

  Future<void> _confirmarApertura() async {
    final monto = double.tryParse(_montoController.text) ?? 0;

    final errorMsg = await ref
        .read(cajaProvider.notifier)
        .abrirCaja(
          token: ref.read(authProvider).token!,
          cajaId: _cajaSeleccionada!.id,
          turnoId: _turnoSeleccionado!.id,
          montoInicial: monto,
        );

    // Si la apertura fue exitosa, la pantalla se desmontará automáticamente
    // debido al cambio de estado en el provider. Por eso verificamos mounted.
    if (!mounted) return;

    final error = ref.read(cajaProvider).errorMessage;
    if (errorMsg != null) {
      showToast(
        context,
        error ?? 'Error al abrir la caja',
        bgColor: Colors.red,
      );
    }
  }
}
