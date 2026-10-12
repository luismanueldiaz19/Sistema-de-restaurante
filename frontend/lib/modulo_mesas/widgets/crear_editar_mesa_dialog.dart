import 'package:flutter/material.dart';
import '../../palletes/app_colors.dart';
import '../../utils/helpers.dart';
import '../models/mesa_model.dart';
import '../providers/mesas_provider.dart';

class CrearEditarMesaDialog extends StatefulWidget {
  final MesaModel? mesa;
  final List<String> areasDisponibles;
  final MesasProvider provider;

  const CrearEditarMesaDialog({
    super.key,
    this.mesa,
    required this.areasDisponibles,
    required this.provider,
  });

  @override
  State<CrearEditarMesaDialog> createState() => _CrearEditarMesaDialogState();
}

class _CrearEditarMesaDialogState extends State<CrearEditarMesaDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nombreController;
  late TextEditingController _areaController;
  late TextEditingController _capacidadController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController(text: widget.mesa?.nombre ?? '');
    _areaController = TextEditingController(text: widget.mesa?.area ?? 'Principal');
    _capacidadController = TextEditingController(
      text: (widget.mesa?.capacidad ?? 4).toString(),
    );
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _areaController.dispose();
    _capacidadController.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final nombre = _nombreController.text.trim();
    final area = _areaController.text.trim().isEmpty ? 'Principal' : _areaController.text.trim();
    final capacidad = int.tryParse(_capacidadController.text.trim()) ?? 4;

    try {
      if (widget.mesa == null) {
        // Crear
        await widget.provider.crearMesa(
          nombre: nombre,
          area: area,
          capacidad: capacidad,
        );
        if (mounted) {
          showToast(context, 'Mesa creada correctamente', bgColor: Colors.green);
          Navigator.pop(context, true);
        }
      } else {
        // Editar
        await widget.provider.actualizarMesa(widget.mesa!.id, {
          'nombre': nombre,
          'area': area,
          'capacidad': capacidad,
        });
        if (mounted) {
          showToast(context, 'Mesa actualizada', bgColor: Colors.green);
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      if (mounted) {
        showToast(context, 'Error: $e', bgColor: Colors.red);
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.mesa != null;
    final sugerenciasAreas = widget.areasDisponibles.where((a) => a != 'Todas').toList();
    if (!sugerenciasAreas.contains('Principal')) sugerenciasAreas.add('Principal');

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 380,
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.table_restaurant, color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    isEditing ? 'Editar Mesa' : 'Nueva Mesa',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Nombre / Número
              TextFormField(
                controller: _nombreController,
                style: const TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  labelText: 'Nombre o Número de la Mesa',
                  labelStyle: const TextStyle(fontSize: 12),
                  hintText: 'Ej. Mesa 1, Terraza 2, Barra A',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Ingresa el nombre de la mesa' : null,
              ),
              const SizedBox(height: 12),
              // Área / Zona
              TextFormField(
                controller: _areaController,
                style: const TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  labelText: 'Área o Ubicación',
                  labelStyle: const TextStyle(fontSize: 12),
                  hintText: 'Ej. Salón Principal, Terraza, VIP',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
              if (sugerenciasAreas.isNotEmpty) ...[
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  children: sugerenciasAreas.map((area) {
                    return ActionChip(
                      label: Text(area, style: const TextStyle(fontSize: 11)),
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                      onPressed: () => setState(() => _areaController.text = area),
                    );
                  }).toList(),
                ),
              ],
              const SizedBox(height: 12),
              // Capacidad
              TextFormField(
                controller: _capacidadController,
                keyboardType: TextInputType.number,
                style: const TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  labelText: 'Capacidad de Personas',
                  labelStyle: const TextStyle(fontSize: 12),
                  hintText: '4',
                  prefixIcon: const Icon(Icons.people_outline, size: 18),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Ingresa la capacidad';
                  if (int.tryParse(val.trim()) == null) return 'Debe ser un número válido';
                  return null;
                },
              ),
              const SizedBox(height: 20),
              // Botones Guardar / Cancelar
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _isSaving ? null : _guardar,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Text(isEditing ? 'Guardar Cambios' : 'Crear Mesa', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
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
