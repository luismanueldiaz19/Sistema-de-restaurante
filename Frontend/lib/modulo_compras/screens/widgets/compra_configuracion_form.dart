import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../palletes/app_colors.dart';
import '../../../../widgets/custom_text_field.dart';
import '../../providers/proveedores_provider.dart';
import '../../providers/nueva_compra_form_provider.dart';
import 'buscador_proveedor_dialog.dart';

class CompraConfiguracionForm extends ConsumerStatefulWidget {
  const CompraConfiguracionForm({super.key});

  @override
  ConsumerState<CompraConfiguracionForm> createState() =>
      _CompraConfiguracionFormState();
}

class _CompraConfiguracionFormState
    extends ConsumerState<CompraConfiguracionForm> {
  late TextEditingController ncfCtrl;
  late TextEditingController numFacturaCtrl;
  late TextEditingController notasCtrl;

  @override
  void initState() {
    super.initState();
    final state = ref.read(nuevaCompraFormProvider);
    ncfCtrl = TextEditingController(text: state.ncf);
    numFacturaCtrl = TextEditingController(text: state.numFactura);
    notasCtrl = TextEditingController(text: state.notas);
  }

  @override
  void dispose() {
    ncfCtrl.dispose();
    numFacturaCtrl.dispose();
    notasCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(nuevaCompraFormProvider);
    final formNotifier = ref.read(nuevaCompraFormProvider.notifier);
    final provState = ref.watch(proveedoresProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Datos del Documento',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.secondary,
          ),
        ),
        const SizedBox(height: 20),
        if (provState.isLoading)
          const Center(child: CircularProgressIndicator())
        else
          InkWell(
            onTap: () async {
              final prov = await showDialog(
                context: context,
                builder: (ctx) =>
                    BuscadorProveedorDialog(proveedores: provState.proveedores),
              );
              if (prov != null) {
                formNotifier.setProveedor(prov.id.toString());
              }
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.business, color: AppColors.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      formState.proveedorId != null
                          ? (() {
                              final matched = provState.proveedores
                                  .where(
                                    (p) =>
                                        p.id.toString() ==
                                        formState.proveedorId,
                                  )
                                  .toList();
                              return matched.isNotEmpty
                                  ? matched.first.nombre
                                  : 'Proveedor Seleccionado';
                            })()
                          : 'Seleccionar Proveedor',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  const Icon(Icons.arrow_drop_down, color: Colors.grey),
                ],
              ),
            ),
          ),
        const SizedBox(height: 16),
        CustomTextField(
          controller: numFacturaCtrl,
          label: 'Nº Factura',
          prefixIcon: Icons.receipt_outlined,
          onChanged: (val) => formNotifier.setNumFactura(val),
        ),
        const SizedBox(height: 16),
        CustomTextField(
          controller: ncfCtrl,
          label: 'NCF',
          prefixIcon: Icons.article_outlined,
          onChanged: (val) => formNotifier.setNcf(val),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          decoration: InputDecoration(
            labelText: 'Tipo',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: Colors.white,
          ),
          value: formState.tipoCompra,
          items: const [
            DropdownMenuItem(value: 'CONTADO', child: Text('CONTADO')),
            DropdownMenuItem(value: 'CREDITO', child: Text('CRÉDITO')),
          ],
          onChanged: (val) {
            if (val != null) formNotifier.setTipoCompra(val);
          },
        ),
        const SizedBox(height: 16),
        ListTile(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          tileColor: Colors.white,
          title: const Text('Fecha de Compra', style: TextStyle(fontSize: 14)),
          subtitle: Text(
            formState.fechaCompra.toLocal().toString().split(' ')[0],
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          trailing: const Icon(
            Icons.calendar_today,
            size: 20,
            color: AppColors.primary,
          ),
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: formState.fechaCompra,
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
            );
            if (date != null) formNotifier.setFechaCompra(date);
          },
        ),
        const SizedBox(height: 16),
        if (formState.tipoCompra == 'CREDITO') ...[
          ListTile(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            tileColor: Colors.white,
            title: const Text('Vencimiento', style: TextStyle(fontSize: 14)),
            subtitle: Text(
              formState.fechaVencimiento?.toLocal().toString().split(' ')[0] ??
                  'Seleccionar',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            trailing: const Icon(Icons.event, size: 20, color: Colors.orange),
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate:
                    formState.fechaVencimiento ?? formState.fechaCompra,
                firstDate: formState.fechaCompra,
                lastDate: DateTime(2100),
              );
              if (date != null) formNotifier.setFechaVencimiento(date);
            },
          ),
          const SizedBox(height: 16),
        ],
        CustomTextField(
          controller: notasCtrl,
          label: 'Notas (Opcional)',
          prefixIcon: Icons.note_alt_outlined,
          maxLines: 2,
          onChanged: (val) => formNotifier.setNotas(val),
        ),
      ],
    );
  }
}
