import 'package:flutter/material.dart';
import '../../palletes/app_colors.dart';
import '../../../modulo_cliente/models/cliente.dart';
import '../../../model/comprobante.dart';

class PanelConfiguracion extends StatelessWidget {
  final Cliente? cliente;
  final Comprobante? comprobante;
  final List<Comprobante> comprobantes;
  final VoidCallback onSelectCliente;
  final Function(Comprobante?) onSelectComprobante;

  const PanelConfiguracion({
    super.key,
    required this.cliente,
    required this.comprobante,
    required this.comprobantes,
    required this.onSelectCliente,
    required this.onSelectComprobante,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'DATOS DE FACTURACIÓN',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1),
          ),
          const SizedBox(height: 16),
          
          // Selector de Cliente
          InkWell(
            onTap: onSelectCliente,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.person_search_rounded, color: AppColors.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cliente?.nombre ?? 'Seleccionar Cliente',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: cliente == null ? Colors.grey : AppColors.azulOscuro,
                          ),
                        ),
                        if (cliente != null)
                          Text(
                            cliente!.documento ?? 'Sin RNC/Cédula',
                            style: const TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.grey),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Selector de Comprobante
          DropdownButtonFormField<Comprobante>(
            value: comprobante,
            isExpanded: true, // 🔥 Evita desbordamiento de texto largo
            decoration: InputDecoration(
              labelText: 'Tipo de Comprobante',
              prefixIcon: const Icon(Icons.description_outlined, color: AppColors.primary),
              filled: true,
              fillColor: Colors.grey.shade50,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            items: comprobantes.map((c) {
              return DropdownMenuItem(
                value: c,
                child: Text("${c.prefijo}${c.tipo} - ${c.nombre}"),
              );
            }).toList(),
            onChanged: onSelectComprobante,
          ),
        ],
      ),
    );
  }
}
