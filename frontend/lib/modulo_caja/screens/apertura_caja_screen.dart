import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../palletes/app_colors.dart';
import '../../../providers/auth_provider.dart';
import '../../../utils/helpers.dart';
import '../providers/caja_provider.dart';
import '../models/caja_models.dart';
import '../services/caja_service.dart';
import '../widgets/cierre_caja_dialog.dart';

class AperturaCajaScreen extends ConsumerStatefulWidget {
  const AperturaCajaScreen({super.key});

  @override
  ConsumerState<AperturaCajaScreen> createState() => _AperturaCajaScreenState();
}

class _AperturaCajaScreenState extends ConsumerState<AperturaCajaScreen> {
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  Future<void> _loadInitialData() async {
    final token = ref.read(authProvider).token;
    if (token == null) return;

    try {
      await ref.read(cajaProvider.notifier).checkEstado(token);
      final cajasData = await _service.getCajas(token);
      final turnosData = await _service.getTurnos(token);

      final cajas = cajasData.map((e) => Caja.fromJson(e)).toList();
      final turnos = turnosData.map((e) => Turno.fromJson(e)).toList();

      if (mounted) {
        setState(() {
          _cajas = cajas;
          _turnos = turnos;
          if (cajas.isNotEmpty) _cajaSeleccionada = cajas.first;
          if (turnos.isNotEmpty) _turnoSeleccionado = turnos.first;
          _loadingData = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingData = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cajaState = ref.watch(cajaProvider);

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text(
          'APERTURA DE CAJA',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.azulOscuro,
        elevation: 0.5,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: _loadingData
              ? const Center(child: CircularProgressIndicator())
              : cajaState.sesionActiva != null
              ? _buildSesionAbiertaCard(cajaState.sesionActiva!)
              : _buildFormularioApertura(cajaState),
        ),
      ),
    );
  }

  Widget _buildSesionAbiertaCard(Map<String, dynamic> sesion) {
    final cajaNombre = sesion['caja']?['nombre'] ?? 'Caja Principal';
    final turnoNombre = sesion['turno']?['nombre'] ?? 'Turno Actual';
    final montoInicial =
        double.tryParse(sesion['monto_inicial']?.toString() ?? '0') ?? 0;
    final fechaApertura = sesion['fecha_apertura'] != null
        ? DateTime.tryParse(sesion['fecha_apertura'].toString())
        : null;

    return Container(
      constraints: const BoxConstraints(maxWidth: 440),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_rounded,
              color: Colors.green,
              size: 40,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            '¡Ya tienes una Caja Abierta!',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.azulOscuro,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Tienes una sesión activa de trabajo. Puedes proceder a facturar o cerrar el turno cuando termines.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                _infoRow('Caja Asignada:', cajaNombre),
                const SizedBox(height: 6),
                _infoRow('Turno Activo:', turnoNombre),
                const SizedBox(height: 6),
                _infoRow(
                  'Fondo Inicial:',
                  FormatterNumber.formatCurrency(montoInicial),
                ),
                if (fechaApertura != null) ...[
                  const SizedBox(height: 6),
                  _infoRow(
                    'Apertura:',
                    FormatterNumber.formatFechaHora(fechaApertura),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 38,
            child: ElevatedButton.icon(
              onPressed: () {
                CierreCajaDialog.show(context, ref);
              },
              icon: const Icon(
                Icons.lock_clock_rounded,
                size: 18,
                color: Colors.white,
              ),
              label: const Text(
                'IR AL CIERRE DE CAJA',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'VOLVER AL MENÚ',
              style: TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.black54),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: AppColors.azulOscuro,
          ),
        ),
      ],
    );
  }

  Widget _buildFormularioApertura(CajaState cajaState) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 400),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.account_balance_wallet_rounded,
              size: 36,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'APERTURA DE TURNO',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: AppColors.azulOscuro,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Selecciona tu caja y registra el monto inicial para comenzar.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 11),
          ),
          const SizedBox(height: 16),

          // Selector de Caja
          _buildDropdown<Caja>(
            label: 'Caja Física',
            value: _cajaSeleccionada,
            items: _cajas
                .map(
                  (c) => DropdownMenuItem(
                    value: c,
                    child: Text(c.nombre, style: const TextStyle(fontSize: 12)),
                  ),
                )
                .toList(),
            onChanged: (val) => setState(() => _cajaSeleccionada = val),
            icon: Icons.storefront_rounded,
          ),
          const SizedBox(height: 12),

          // Selector de Turno
          _buildDropdown<Turno>(
            label: 'Turno de Trabajo',
            value: _turnoSeleccionado,
            items: _turnos
                .map(
                  (t) => DropdownMenuItem(
                    value: t,
                    child: Text(t.nombre, style: const TextStyle(fontSize: 12)),
                  ),
                )
                .toList(),
            onChanged: (val) => setState(() => _turnoSeleccionado = val),
            icon: Icons.access_time_rounded,
          ),
          const SizedBox(height: 12),

          // Monto Inicial
          TextFormField(
            controller: _montoController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              labelText: 'Monto Inicial en Efectivo (Fondo)',
              hintText: '0.00',
              labelStyle: const TextStyle(fontSize: 11),
              prefixIcon: const Icon(
                Icons.payments_outlined,
                color: AppColors.primary,
                size: 18,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 8,
              ),
              isDense: true,
            ),
          ),
          const SizedBox(height: 18),

          SizedBox(
            width: double.infinity,
            height: 38,
            child: ElevatedButton(
              onPressed: cajaState.isLoading ? null : _confirmarApertura,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 2,
              ),
              child: cajaState.isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
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
                        fontSize: 12,
                      ),
                    ),
            ),
          ),
        ],
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
      initialValue: value,
      items: items,
      onChanged: onChanged,
      style: const TextStyle(fontSize: 12, color: Colors.black87),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 11),
        prefixIcon: Icon(icon, color: AppColors.primary, size: 18),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        isDense: true,
      ),
    );
  }

  Future<void> _confirmarApertura() async {
    if (_cajaSeleccionada == null || _turnoSeleccionado == null) {
      showToast(
        context,
        'Selecciona una caja y un turno',
        bgColor: Colors.orange,
      );
      return;
    }

    final monto = double.tryParse(_montoController.text) ?? 0;
    final token = ref.read(authProvider).token;
    if (token == null) return;

    final errorMsg = await ref
        .read(cajaProvider.notifier)
        .abrirCaja(
          token: token,
          cajaId: _cajaSeleccionada!.id,
          turnoId: _turnoSeleccionado!.id,
          montoInicial: monto,
        );

    if (!mounted) return;

    if (errorMsg != null) {
      showToast(context, errorMsg, bgColor: Colors.red);
    } else {
      showToast(context, 'Caja abierta exitosamente', bgColor: Colors.green);
      Navigator.pop(context);
    }
  }
}
