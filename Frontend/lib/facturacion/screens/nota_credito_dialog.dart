import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../utils/constants.dart';
import '../../palletes/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../model/factura.dart';
import '../providers/facturacion_historial_provider.dart';

class NotaCreditoDialog extends ConsumerStatefulWidget {
  final Factura factura;

  const NotaCreditoDialog({super.key, required this.factura});

  @override
  ConsumerState<NotaCreditoDialog> createState() => _NotaCreditoDialogState();
}

class _NotaCreditoDialogState extends ConsumerState<NotaCreditoDialog> {
  final Map<int, double> _cantidadesADevolver = {};
  final _motivoController = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    for (var det in widget.factura.detalles ?? []) {
      _cantidadesADevolver[det.productoId!] = 0.0;
    }
  }

  double get _totalADevolver {
    double total = 0;
    for (var det in widget.factura.detalles ?? []) {
      final cantidad = _cantidadesADevolver[det.productoId!] ?? 0;
      if (cantidad > 0) {
        final totalLinea = det.total ?? 0.0;
        final cantOriginal = (det.cantidad ?? 1.0).toDouble();
        if (cantOriginal > 0) {
          final precioFinalConItbis = totalLinea / cantOriginal;
          total += precioFinalConItbis * cantidad;
        }
      }
    }
    return total;
  }

  Future<void> _guardar() async {
    final detallesDevolucion = <Map<String, dynamic>>[];
    for (var det in widget.factura.detalles ?? []) {
      final cant = _cantidadesADevolver[det.productoId!];
      if (cant != null && cant > 0) {
        detallesDevolucion.add({
          'producto_id': det.productoId,
          'cantidad': cant,
        });
      }
    }

    if (detallesDevolucion.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Debes seleccionar al menos un artículo para devolver.',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_motivoController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El motivo es obligatorio.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    final token = ref.read(authProvider).token!;
    final newNoteId = await ref
        .read(facturacionHistorialProvider.notifier)
        .generarNotaCredito(
          token,
          widget.factura.id!,
          detallesDevolucion,
          _motivoController.text.trim(),
        );

    if (mounted) {
      setState(() => _isSaving = false);
      if (newNoteId != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nota de crédito generada exitosamente.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);

        final urlWithToken = Uri.parse(
          "$hostName/api/notas-credito/$newNoteId/pdf?token=$token",
        );
        if (await canLaunchUrl(urlWithToken)) {
          await launchUrl(urlWithToken, mode: LaunchMode.externalApplication);
        }
      } else {
        final error = ref.read(facturacionHistorialProvider).error;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $error'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Container(
        width: 600,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Generar Devolución / Nota de Crédito (Factura #${widget.factura.id})",
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.azulOscuro,
              ),
            ),
            const Divider(),
            const SizedBox(height: 10),
            const Text(
              "Selecciona las cantidades a devolver por cada artículo:",
              style: TextStyle(color: Colors.blueGrey),
            ),
            const SizedBox(height: 10),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: widget.factura.detalles?.length ?? 0,
                separatorBuilder: (c, i) => const Divider(),
                itemBuilder: (context, index) {
                  final det = widget.factura.detalles![index];
                  final maxCant = (det.cantidad ?? 0).toDouble();
                  final cantActual =
                      _cantidadesADevolver[det.productoId!] ?? 0.0;
                  return Row(
                    children: [
                      Expanded(
                        child: Text(
                          "${det.descripcion ?? det.producto?.nombre ?? 'Producto'} (Facturado: $maxCant)",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            color: Colors.red,
                            onPressed: cantActual > 0
                                ? () => setState(
                                    () =>
                                        _cantidadesADevolver[det.productoId!] =
                                            cantActual - 1,
                                  )
                                : null,
                          ),
                          Text(
                            cantActual.toStringAsFixed(0),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline),
                            color: Colors.green,
                            onPressed: cantActual < maxCant
                                ? () => setState(
                                    () =>
                                        _cantidadesADevolver[det.productoId!] =
                                            cantActual + 1,
                                  )
                                : null,
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _motivoController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: "Motivo de la Devolución",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              color: Colors.red.shade50,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "TOTAL A DEVOLVER AL CLIENTE:",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  Text(
                    "RD\$ ${_totalADevolver.toStringAsFixed(2)}",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _isSaving ? null : () => Navigator.pop(context),
                  child: const Text(
                    "Cancelar",
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: _isSaving ? null : _guardar,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.receipt_long),
                  label: Text(_isSaving ? "Procesando..." : "Generar E34"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
