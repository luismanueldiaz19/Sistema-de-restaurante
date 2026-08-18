import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../palletes/app_colors.dart';
import '../../../../widgets/custom_text_field.dart';
import '../../providers/proveedores_provider.dart';
import '../../providers/nueva_compra_form_provider.dart';
import 'buscador_proveedor_dialog.dart';

class CompraConfiguracionForm extends ConsumerStatefulWidget {
  final bool isCompact;
  const CompraConfiguracionForm({super.key, this.isCompact = false});

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
        const SizedBox(height: 16),
        if (provState.isLoading)
          const Center(child: CircularProgressIndicator())
        else if (widget.isCompact)
          // -------------------------------------------------------------
          // DISEÑO COMPACTO (TABLET/ESCRITORIO)
          // -------------------------------------------------------------
          Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 3, child: _buildProveedor(formState, provState, formNotifier)),
                  const SizedBox(width: 12),
                  Expanded(flex: 2, child: _buildTipoCompra(formState, formNotifier)),
                ],
              ),
              const SizedBox(height: 12),
              if (esInformal)
                _buildAvisoInformal()
              else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildNCF(formNotifier)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildNumFactura(formNotifier)),
                  ],
                ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildFechaCompra(formState, formNotifier)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: formState.tipoCompra == 'CREDITO'
                        ? _buildVencimiento(formState, formNotifier)
                        : const SizedBox(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              CustomTextField(
                controller: notasCtrl,
                label: 'Notas (Opcional)',
                prefixIcon: Icons.note_alt_outlined,
                maxLines: 1,
                onChanged: (val) => formNotifier.setNotas(val),
              ),
            ],
          )
        else
          // -------------------------------------------------------------
          // DISEÑO NORMAL (MÓVIL)
          // -------------------------------------------------------------
          Column(
            children: [
              _buildProveedor(formState, provState, formNotifier),
              const SizedBox(height: 16),
              _buildNumFactura(formNotifier),
              const SizedBox(height: 16),
              if (esInformal) _buildAvisoInformal() else _buildNCF(formNotifier),
              const SizedBox(height: 16),
              _buildTipoCompra(formState, formNotifier),
              const SizedBox(height: 16),
              _buildFechaCompra(formState, formNotifier),
              const SizedBox(height: 16),
              if (formState.tipoCompra == 'CREDITO') ...[
                _buildVencimiento(formState, formNotifier),
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
          ),
      ],
    );
  }

  // --- WIDGET EXTRACTS FOR REUSE ---

  Widget _buildProveedor(formState, provState, formNotifier) {
    return InkWell(
      onTap: () async {
        final prov = await showDialog(
          context: context,
          builder: (ctx) => BuscadorProveedorDialog(proveedores: provState.proveedores),
        );
        if (prov != null) formNotifier.setProveedor(prov.id.toString());
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            const Icon(Icons.business, color: AppColors.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                formState.proveedorId != null
                    ? (() {
                        final matched = provState.proveedores.where((p) => p.id.toString() == formState.proveedorId).toList();
                        return matched.isNotEmpty ? matched.first.nombre : 'Proveedor Seleccionado';
                      })()
                    : 'Seleccionar Proveedor',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(Icons.arrow_drop_down, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildNumFactura(formNotifier) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
                  setState(() {});
                },
              ),
            ),
            const SizedBox(width: 8),
            Tooltip(
              message: 'Generar número temporal',
              child: InkWell(
                onTap: _autoGenerarNumFactura,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  height: 47,
                  width: 47,
                  margin: const EdgeInsets.only(top: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.25), width: 1.2),
                  ),
                  child: const Icon(Icons.auto_fix_high_rounded, color: AppColors.primary, size: 22),
                ),
              ),
            ),
          ],
        ),
        if (numFacturaCtrl.text.startsWith('TEMP-'))
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 4),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 12, color: Colors.orange.shade600),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Número temporal — reemplazar',
                    style: TextStyle(fontSize: 10, color: Colors.orange.shade700, fontStyle: FontStyle.italic),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildNCF(formNotifier) {
    return CustomTextField(
      controller: ncfCtrl,
      label: 'NCF',
      prefixIcon: Icons.article_outlined,
      onChanged: (val) => formNotifier.setNcf(val),
    );
  }

  Widget _buildAvisoInformal() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
      ),
      child: const Row(
        children: [
          Icon(Icons.receipt_long, color: Colors.orange, size: 20),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Proveedor Informal (E41)',
              style: TextStyle(fontSize: 11, color: Colors.deepOrange),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipoCompra(formState, formNotifier) {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: 'Tipo',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade300)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade300)),
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
    );
  }

  Widget _buildFechaCompra(formState, formNotifier) {
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.shade300)),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Fecha Compra', style: TextStyle(fontSize: 12, color: Colors.grey)),
        subtitle: Text(
          formState.fechaCompra.toLocal().toString().split(' ')[0],
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        trailing: const Icon(Icons.calendar_today, size: 18, color: AppColors.primary),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
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
    );
  }

  Widget _buildVencimiento(formState, formNotifier) {
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.shade300)),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Vencimiento', style: TextStyle(fontSize: 12, color: Colors.grey)),
        subtitle: Text(
          formState.fechaVencimiento?.toLocal().toString().split(' ')[0] ?? 'Seleccionar',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        trailing: const Icon(Icons.event, size: 18, color: Colors.orange),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
        onTap: () async {
          final date = await showDatePicker(
            context: context,
            initialDate: formState.fechaVencimiento ?? formState.fechaCompra,
            firstDate: formState.fechaCompra,
            lastDate: DateTime(2100),
          );
          if (date != null) formNotifier.setFechaVencimiento(date);
        },
      ),
    );
  }
}
