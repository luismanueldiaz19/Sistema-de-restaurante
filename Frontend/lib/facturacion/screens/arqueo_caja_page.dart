import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../palletes/app_colors.dart';
import '../../utils/helpers.dart';
import '../providers/caja_provider.dart';

class ArqueoCajaPage extends ConsumerStatefulWidget {
  const ArqueoCajaPage({super.key});

  @override
  ConsumerState<ArqueoCajaPage> createState() => _ArqueoCajaPageState();
}

class _ArqueoCajaPageState extends ConsumerState<ArqueoCajaPage> {
  final _fisicoController = TextEditingController(text: '0.00');
  final _comentarioController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final sesion = ref.watch(cajaProvider).sesionActiva;

    if (sesion == null)
      return const Scaffold(body: Center(child: Text('No hay sesión activa')));

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('ARQUEO Y CIERRE DE CAJA'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.azulOscuro,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              children: [
                _buildResumenTurno(sesion),
                const SizedBox(height: 32),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Panel de Conteo
                    Expanded(flex: 3, child: _buildPanelConteo()),
                    const SizedBox(width: 32),
                    // Panel de Resultado
                    Expanded(flex: 2, child: _buildPanelResultado(sesion)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResumenTurno(dynamic sesion) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.azulOscuro,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _infoItem(
            'CAJA',
            sesion.nombreCaja ?? 'N/A',
            Icons.storefront_rounded,
          ),
          _infoItem(
            'TURNO',
            sesion.nombreTurno ?? 'N/A',
            Icons.access_time_rounded,
          ),
          _infoItem(
            'APERTURA',
            formatFechaHora(sesion.fechaApertura),
            Icons.calendar_today_rounded,
          ),
          _infoItem(
            'FONDO',
            formatCurrency(sesion.montoInicial),
            Icons.account_balance_wallet_rounded,
          ),
        ],
      ),
    );
  }

  Widget _infoItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 20),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildPanelConteo() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'CONTEO FÍSICO',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
          ),
          const SizedBox(height: 24),
          textFieldWidgetUI(
            label: 'Total Efectivo en Caja',
            hintText: '0.00',
            controller: _fisicoController,
            keyboardType: TextInputType.number,
            prefixIcon: Icons.payments_rounded,
            width: double.infinity,
            onChanged: (val) => setState(() {}),
          ),
          const SizedBox(height: 24),
          textFieldWidgetUI(
            label: 'Notas / Observaciones del Cierre',
            hintText: 'Ej: Diferencia por cambio...',
            controller: _comentarioController,
            prefixIcon: Icons.comment_rounded,
            width: double.infinity,
          ),
        ],
      ),
    );
  }

  Widget _buildPanelResultado(dynamic sesion) {
    final montoFisico = double.tryParse(_fisicoController.text) ?? 0;
    // En una app real, el backend nos daría las ventas actuales.
    // Por ahora simularemos que el esperado es el inicial para pruebas visuales.
    final esperado = sesion.montoInicial;
    final diferencia = montoFisico - esperado;

    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          _resumenFila('Esperado:', formatCurrency(esperado)),
          const Divider(height: 32),
          _resumenFila('Contado:', formatCurrency(montoFisico)),
          const Divider(height: 32),
          Text(
            diferencia == 0
                ? 'CAJA CUADRADA'
                : (diferencia > 0 ? 'SOBRANTE' : 'FALTANTE'),
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: diferencia == 0
                  ? Colors.green
                  : (diferencia > 0 ? Colors.blue : Colors.red),
            ),
          ),
          Text(
            formatCurrency(diferencia),
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: diferencia == 0
                  ? Colors.green
                  : (diferencia > 0 ? Colors.blue : Colors.red),
            ),
          ),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton(
              onPressed: () => _confirmarCierre(montoFisico),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.azulOscuro,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              child: const Text(
                'CERRAR CAJA DEFINITIVO',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _resumenFila(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.grey,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ],
    );
  }

  Future<void> _confirmarCierre(double monto) async {
    final confirmar = await showConfirmationDialogOnyAsk(
      context,
      '¿Estás seguro de cerrar la caja? Una vez cerrada no podrás realizar más ventas en este turno.',
    );

    if (confirmar == true) {
      final success = await ref
          .read(cajaProvider.notifier)
          .cerrarCaja(monto, comentario: _comentarioController.text);

      if (success && mounted) {
        showToast(
          context,
          'Caja cerrada y arqueada correctamente',
          bgColor: Colors.green,
        );
        Navigator.pop(context);
      }
    }
  }
}
