import 'package:flutter/material.dart';
import '../../palletes/app_colors.dart';
import '../../../modulo_cliente/models/cliente.dart';
import '../../../model/comprobante.dart';

class PanelConfiguracion extends StatelessWidget {
  final Cliente? cliente;
  final Comprobante? comprobante;
  final List<Comprobante> comprobantes;
  final String tipoFactura;
  final int diasCredito;
  final String nota;
  final VoidCallback onSelectCliente;
  final Function(Comprobante?) onSelectComprobante;
  final Function(String) onCambiarTipo;
  final Function(int) onCambiarDias;
  final Function(String) onCambiarNota;

  const PanelConfiguracion({
    super.key,
    required this.cliente,
    required this.comprobante,
    required this.comprobantes,
    required this.tipoFactura,
    required this.diasCredito,
    required this.nota,
    required this.onSelectCliente,
    required this.onSelectComprobante,
    required this.onCambiarTipo,
    required this.onCambiarDias,
    required this.onCambiarNota,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'CONFIGURACIÓN',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: AppColors.secondary,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Selector de Cliente
          const _Label(text: 'CLIENTE'),
          const SizedBox(height: 8),
          InkWell(
            onTap: onSelectCliente,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.light,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade100),
              ),
              child: Row(
                children: [
                  const Icon(Icons.person_outline, color: AppColors.primary, size: 22),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cliente?.nombre ?? 'Seleccionar Cliente',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                            color: cliente == null ? Colors.grey : AppColors.secondary,
                          ),
                        ),
                        if (cliente != null)
                          Text(
                            cliente!.rncCedula ?? 'Sin identificación',
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                          ),
                      ],
                    ),
                  ),
                  const Icon(Icons.keyboard_arrow_right, color: Colors.grey, size: 20),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Tipo de Factura (Contado/Crédito)
          const _Label(text: 'CONDICIÓN DE PAGO'),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildTipoOption(
                label: 'Contado',
                isSelected: tipoFactura == 'contado',
                onTap: () => onCambiarTipo('contado'),
              ),
              if (cliente != null && (cliente?.diasCredito ?? 0) > 0) ...[
                const SizedBox(width: 12),
                _buildTipoOption(
                  label: 'Crédito',
                  isSelected: tipoFactura == 'credito',
                  onTap: () => onCambiarTipo('credito'),
                ),
              ],
            ],
          ),

          if (tipoFactura == 'credito') ...[
            const SizedBox(height: 24),
            const _Label(text: 'DÍAS DE CRÉDITO'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.light,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade100),
              ),
              child: TextFormField(
                key: ValueKey(cliente?.id),
                initialValue: diasCredito.toString(),
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  hintText: 'Ej. 30',
                  border: InputBorder.none,
                ),
                onChanged: (v) => onCambiarDias(int.tryParse(v) ?? 0),
              ),
            ),
          ],

          const SizedBox(height: 24),

          // Notas de la Factura
          const _Label(text: 'NOTAS / DIRECCIÓN'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.light,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade100),
            ),
            child: TextFormField(
              initialValue: nota,
              maxLines: 3,
              style: const TextStyle(fontSize: 13),
              decoration: const InputDecoration(
                hintText: 'Ej. Dirección de entrega, indicaciones...',
                border: InputBorder.none,
              ),
              onChanged: onCambiarNota,
            ),
          ),

          const SizedBox(height: 24),

          // Selector de Comprobante
          const _Label(text: 'TIPO DE COMPROBANTE'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.light,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade100),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButtonFormField<Comprobante>(
                value: comprobante,
                isExpanded: true,
                decoration: const InputDecoration(border: InputBorder.none),
                icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
                hint: const Text(
                  'Seleccionar...',
                  style: TextStyle(fontSize: 14),
                ),
                items: comprobantes.map((c) {
                  return DropdownMenuItem(
                    value: c,
                    child: Text(
                      "${c.prefijo}${c.tipo} - ${c.nombre}",
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: onSelectComprobante,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipoOption({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : AppColors.light,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? AppColors.primary : Colors.grey.shade100,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        color: Colors.grey.shade400,
        letterSpacing: 0.5,
      ),
    );
  }
}
