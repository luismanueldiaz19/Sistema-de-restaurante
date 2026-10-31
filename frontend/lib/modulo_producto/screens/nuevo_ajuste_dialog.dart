import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../palletes/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/buscador_dialog.dart';
import '../models/producto.dart';
import '../providers/inventario_provider.dart';
import '../providers/producto_provider.dart';

class NuevoAjusteDialog extends ConsumerStatefulWidget {
  final Producto? productoInicial;

  const NuevoAjusteDialog({
    super.key,
    this.productoInicial,
  });

  @override
  ConsumerState<NuevoAjusteDialog> createState() => _NuevoAjusteDialogState();
}

class _NuevoAjusteDialogState extends ConsumerState<NuevoAjusteDialog> {
  Producto? _productoSeleccionado;
  String _tipoAjuste = 'SALIDA'; // Por defecto las mermas/salidas son más comunes
  final _cantidadController = TextEditingController();
  final _motivoController = TextEditingController();
  bool _isSaving = false;

  final List<String> _motivosSalida = [
    'Merma / Desperdicio',
    'Vencimiento',
    'Avería / Rotura',
    'Conteo físico (Faltante)',
    'Despacho a cocina',
    'Consumo interno',
  ];

  final List<String> _motivosEntrada = [
    'Conteo físico (Sobrante)',
    'Compra de emergencia',
    'Corrección de inventario',
    'Devolución de cocina',
  ];

  @override
  void initState() {
    super.initState();
    _productoSeleccionado = widget.productoInicial;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = ref.read(authProvider);
      if (ref.read(productoProvider).productos.isEmpty && auth.token != null) {
        ref.read(productoProvider.notifier).loadProductos(auth.token!, search: '');
      }
    });
  }

  @override
  void dispose() {
    _cantidadController.dispose();
    _motivoController.dispose();
    super.dispose();
  }

  void _seleccionarProducto() {
    // Filtramos únicamente los productos que manejan inventario y NO sean servicios
    final todos = ref.read(productoProvider).productos;
    final productosInventariables = todos.where((p) {
      final maneja = p.manejaInventario ?? false;
      final noEsServicio = (p.tipoProducto ?? '').toUpperCase() != 'SERVICIO';
      return maneja && noEsServicio;
    }).toList();

    showDialog(
      context: context,
      builder: (context) => BuscadorDialog<Producto>(
        items: productosInventariables,
        itemLabel: (p) => "${p.nombre} (${p.codigo ?? '#${p.id}'}) - Stock: ${p.stockActual ?? 0} ${p.unidadMedida?.nombre ?? ''}",
        onSelected: (p) {
          setState(() {
            _productoSeleccionado = p;
          });
        },
      ),
    );
  }

  Future<void> _guardarAjuste() async {
    if (_productoSeleccionado == null) {
      _mostrarMensaje('Debes seleccionar un producto inventariable.', Colors.red);
      return;
    }

    final cantidad = double.tryParse(_cantidadController.text);
    if (cantidad == null || cantidad <= 0) {
      _mostrarMensaje('Ingresa una cantidad válida mayor a 0.', Colors.red);
      return;
    }

    if (_motivoController.text.trim().isEmpty) {
      _mostrarMensaje('Escribe o selecciona un motivo para justificar el ajuste.', Colors.red);
      return;
    }

    setState(() => _isSaving = true);

    final auth = ref.read(authProvider);
    final success = await ref.read(inventarioProvider.notifier).registrarAjuste(
          _productoSeleccionado!.id!,
          _tipoAjuste,
          cantidad,
          _motivoController.text.trim(),
          auth.token!,
        );

    if (mounted) {
      setState(() => _isSaving = false);
      if (success) {
        // Refrescar también catálogo de productos
        ref.read(productoProvider.notifier).loadProductos(auth.token!, search: '');
        _mostrarMensaje('Ajuste de inventario guardado correctamente.', Colors.green);
        Navigator.pop(context, true);
      } else {
        final error = ref.read(inventarioProvider).error ?? 'Error desconocido';
        _mostrarMensaje('Error: $error', Colors.red);
      }
    }
  }

  void _mostrarMensaje(String texto, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(texto, style: const TextStyle(fontSize: 13)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Widget _buildStockBadge(double stock, double minimo) {
    Color bg;
    Color fg;
    String label;

    if (stock < 0) {
      bg = Colors.red.shade50;
      fg = Colors.red.shade700;
      label = "Déficit ($stock)";
    } else if (stock == 0) {
      bg = Colors.red.shade50;
      fg = Colors.red.shade700;
      label = "Sin existencias (0)";
    } else if (stock <= minimo) {
      bg = Colors.amber.shade50;
      fg = Colors.amber.shade800;
      label = "Bajo mínimo ($stock)";
    } else {
      bg = Colors.green.shade50;
      fg = Colors.green.shade700;
      label = "Disponible ($stock)";
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: fg.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final stockActual = _productoSeleccionado?.stockActual ?? 0.0;
    final stockMinimo = _productoSeleccionado?.stockMinimo ?? 0.0;
    final double? cantidadDigitada = double.tryParse(_cantidadController.text);
    final double? stockProyectado = cantidadDigitada != null
        ? (_tipoAjuste == 'ENTRADA' ? stockActual + cantidadDigitada : stockActual - cantidadDigitada)
        : null;

    final motivosDisponibles = _tipoAjuste == 'SALIDA' ? _motivosSalida : _motivosEntrada;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Encabezado compacto
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.tune, color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      "Ajuste Manual de Inventario",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.azulOscuro,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20, color: Colors.grey),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 14),

              // Selector de Producto
              const Text(
                "Producto Inventariable",
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.blueGrey),
              ),
              const SizedBox(height: 6),
              InkWell(
                onTap: _seleccionarProducto,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.inventory_2_outlined, size: 18, color: Colors.grey.shade700),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _productoSeleccionado != null
                              ? "${_productoSeleccionado!.nombre} (${_productoSeleccionado!.codigo ?? '#${_productoSeleccionado!.id}'})"
                              : "Buscar producto en inventario...",
                          style: TextStyle(
                            fontSize: 13,
                            color: _productoSeleccionado != null ? Colors.black87 : Colors.grey.shade500,
                            fontWeight: _productoSeleccionado != null ? FontWeight.w500 : FontWeight.normal,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (_productoSeleccionado != null) ...[
                        _buildStockBadge(stockActual, stockMinimo),
                        const SizedBox(width: 6),
                      ],
                      const Icon(Icons.arrow_drop_down, color: Colors.grey, size: 20),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Selector Tipo de Ajuste (Entrada vs Salida)
              const Text(
                "Naturaleza del Ajuste",
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.blueGrey),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _tipoAjuste = 'SALIDA'),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: _tipoAjuste == 'SALIDA' ? Colors.red.shade50 : Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _tipoAjuste == 'SALIDA' ? Colors.red.shade400 : Colors.grey.shade300,
                            width: _tipoAjuste == 'SALIDA' ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.remove_circle_outline, size: 16, color: _tipoAjuste == 'SALIDA' ? Colors.red.shade700 : Colors.grey),
                            const SizedBox(width: 6),
                            Text(
                              "Salida / Merma (-)",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: _tipoAjuste == 'SALIDA' ? Colors.red.shade700 : Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _tipoAjuste = 'ENTRADA'),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: _tipoAjuste == 'ENTRADA' ? Colors.green.shade50 : Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _tipoAjuste == 'ENTRADA' ? Colors.green.shade400 : Colors.grey.shade300,
                            width: _tipoAjuste == 'ENTRADA' ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_circle_outline, size: 16, color: _tipoAjuste == 'ENTRADA' ? Colors.green.shade700 : Colors.grey),
                            const SizedBox(width: 6),
                            Text(
                              "Entrada / Sobrante (+)",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: _tipoAjuste == 'ENTRADA' ? Colors.green.shade700 : Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Cantidad y Proyección
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Cantidad a Ajustar",
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.blueGrey),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _cantidadController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          onChanged: (_) => setState(() {}),
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                          decoration: InputDecoration(
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            hintText: "Ej. 2.5",
                            suffixText: _productoSeleccionado?.unidadMedida?.nombre ?? 'un.',
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (stockProyectado != null) ...[
                    const SizedBox(width: 14),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        margin: const EdgeInsets.only(top: 22),
                        decoration: BoxDecoration(
                          color: stockProyectado < 0 ? Colors.red.shade50 : Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: stockProyectado < 0 ? Colors.red.shade200 : Colors.blue.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Stock Resultante:",
                              style: TextStyle(
                                fontSize: 11,
                                color: stockProyectado < 0 ? Colors.red.shade900 : Colors.blue.shade900,
                              ),
                            ),
                            Text(
                              "${stockProyectado.toStringAsFixed(2)} ${_productoSeleccionado?.unidadMedida?.nombre ?? ''}",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: stockProyectado < 0 ? Colors.red.shade700 : Colors.blue.shade800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 14),

              // Motivos rápidos (Chips compactos)
              const Text(
                "Motivo / Causa",
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.blueGrey),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: motivosDisponibles.map((motivo) {
                  final isSelected = _motivoController.text == motivo;
                  return ChoiceChip(
                    label: Text(motivo, style: TextStyle(fontSize: 11, color: isSelected ? Colors.white : Colors.blueGrey.shade800)),
                    selected: isSelected,
                    selectedColor: AppColors.primary,
                    backgroundColor: Colors.grey.shade100,
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                    onSelected: (val) {
                      setState(() {
                        _motivoController.text = val ? motivo : '';
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 6),

              // Campo de texto para detalle libre
              TextFormField(
                controller: _motivoController,
                style: const TextStyle(fontSize: 12),
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: "Detalle o justificación del ajuste...",
                  hintStyle: const TextStyle(fontSize: 12),
                  isDense: true,
                  contentPadding: const EdgeInsets.all(10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(height: 18),

              // Botones de acción
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: _isSaving ? null : () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text("Cancelar", style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: _isSaving ? null : _guardarAjuste,
                    icon: _isSaving
                        ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.check, size: 16),
                    label: Text(_isSaving ? "Guardando..." : "Confirmar Ajuste", style: const TextStyle(fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _tipoAjuste == 'SALIDA' ? Colors.red.shade600 : Colors.green.shade600,
                      foregroundColor: Colors.white,
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
