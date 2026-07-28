import 'dart:math';
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

  /// Genera un número de factura temporal con formato TEMP-YYYYMMDD-XXXX.
  /// Se usa cuando el usuario no tiene la factura original del proveedor.
  String _generarNumFacturaTemporal() {
    final now = DateTime.now();
    final fecha =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    final sufijo = (Random().nextInt(9000) + 1000).toString(); // 1000–9999
    return 'TEMP-$fecha-$sufijo';
  }

  void _autoGenerarNumFactura() {
    final generado = _generarNumFacturaTemporal();
    numFacturaCtrl.text = generado;
    ref.read(nuevaCompraFormProvider.notifier).setNumFactura(generado);
    setState(() {}); // refresca el aviso naranja
  }

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

    final proveedorSeleccionado = formState.proveedorId != null
        ? provState.proveedores
              .where((p) => p.id.toString() == formState.proveedorId)
              .firstOrNull
        : null;
    final esInformal = proveedorSeleccionado?.esInformal ?? false;

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
        // ── Nº Factura + botón generador opcional ──────────────────────────
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: CustomTextField(
                controller: numFacturaCtrl,
                label: 'Nº Factura',
                prefixIcon: Icons.receipt_outlined,
                onChanged: (val) {
                  formNotifier.setNumFactura(val);
                  setState(() {}); // refresca el aviso TEMP
                },
              ),
            ),
            const SizedBox(width: 8),
            Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Text(
                  ' ',
                  style: TextStyle(fontSize: 13),
                ), // Dummy label para alinear
                const SizedBox(height: 8),
                Tooltip(
                  message:
                      'Generar número temporal\n(cuando no tiene la factura original)',
                  preferBelow: true,
                  child: InkWell(
                    onTap: _autoGenerarNumFactura,
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      height: 47,
                      width: 47,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.25),
                          width: 1.2,
                        ),
                      ),
                      child: const Icon(
                        Icons.auto_fix_high_rounded,
                        color: AppColors.primary,
                        size: 22,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        // Si el número fue generado automáticamente, mostrar aviso sutil
        if (numFacturaCtrl.text.startsWith('TEMP-'))
          Padding(
            padding: const EdgeInsets.only(top: 5, left: 4),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 12,
                  color: Colors.orange.shade600,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Número temporal — reemplazar con el original',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.orange.shade700,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
        // ──────────────────────────────────────────────────────────────────────
        const SizedBox(height: 16),
        if (esInformal)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.receipt_long, color: Colors.orange),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Proveedor Informal: Se generará automáticamente un Comprobante de Compras (E41) y se retendrá el ITBIS.',
                    style: TextStyle(fontSize: 12, color: Colors.deepOrange),
                  ),
                ),
              ],
            ),
          )
        else
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
