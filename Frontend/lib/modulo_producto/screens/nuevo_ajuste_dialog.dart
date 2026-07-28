import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../palletes/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/buscador_dialog.dart';
import '../models/producto.dart';
import '../providers/inventario_provider.dart';
import '../providers/producto_provider.dart';

class NuevoAjusteDialog extends ConsumerStatefulWidget {
  const NuevoAjusteDialog({super.key});

  @override
  ConsumerState<NuevoAjusteDialog> createState() => _NuevoAjusteDialogState();
}

class _NuevoAjusteDialogState extends ConsumerState<NuevoAjusteDialog> {
  Producto? _productoSeleccionado;
  String _tipoAjuste = 'ENTRADA';
  final _cantidadController = TextEditingController();
  final _motivoController = TextEditingController();

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = ref.read(authProvider);
      // Asegurar que los productos esten cargados
      if (ref.read(productoProvider).productos.isEmpty) {
        ref.read(productoProvider.notifier).loadProductos(auth.token!);
      }
    });
  }

  void _seleccionarProducto() {
    final productos = ref.read(productoProvider).productos;
    showDialog(
      context: context,
      builder: (context) => BuscadorDialog<Producto>(
        items: productos,
        itemLabel: (p) => "${p.nombre} (${p.codigo ?? p.id}) - Stock: ${p.stockActual}",
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes seleccionar un producto.'), backgroundColor: Colors.red),
      );
      return;
    }
    
    final cantidad = double.tryParse(_cantidadController.text);
    if (cantidad == null || cantidad <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La cantidad debe ser mayor a 0.'), backgroundColor: Colors.red),
      );
      return;
    }

    if (_motivoController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes proveer un motivo para el ajuste.'), backgroundColor: Colors.red),
      );
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ajuste guardado exitosamente.'), backgroundColor: Colors.green),
        );
        Navigator.pop(context); // Cierra el modal y refrescara la pantalla por detras
      } else {
        final error = ref.read(inventarioProvider).error;
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
        width: 500,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Nuevo Ajuste de Inventario",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.azulOscuro,
              ),
            ),
            const Divider(),
            const SizedBox(height: 16),

            // Producto
            const Text("Producto", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            InkWell(
              onTap: _seleccionarProducto,
              child: InputDecorator(
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        _productoSeleccionado != null 
                            ? "${_productoSeleccionado!.nombre} (Stock actual: ${_productoSeleccionado!.stockActual})"
                            : "Seleccionar Producto...",
                        style: TextStyle(
                          color: _productoSeleccionado != null ? Colors.black87 : Colors.grey,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Icon(Icons.search, color: Colors.grey),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Tipo de Ajuste y Cantidad
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Tipo de Ajuste", style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _tipoAjuste,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'ENTRADA', child: Text("Entrada (Sumar)", style: TextStyle(color: Colors.green))),
                          DropdownMenuItem(value: 'SALIDA', child: Text("Salida (Restar)", style: TextStyle(color: Colors.red))),
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() => _tipoAjuste = val);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Cantidad", style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _cantidadController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: "Ej. 11",
                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Motivo
            const Text("Motivo / Justificación", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _motivoController,
              maxLines: 2,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: "Ej. Error en cantidad de compra, mercancia dañada...",
              ),
            ),
            const SizedBox(height: 24),

            // Botones
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _isSaving ? null : () => Navigator.pop(context),
                  child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: _isSaving ? null : _guardarAjuste,
                  icon: _isSaving 
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.save),
                  label: Text(_isSaving ? "Guardando..." : "Guardar Ajuste"),
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
