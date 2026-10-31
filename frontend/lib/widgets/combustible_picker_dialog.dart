import 'package:flutter/material.dart';

class CombustiblePickerDialog extends StatefulWidget {
  final String? initialSelected;

  const CombustiblePickerDialog({this.initialSelected, super.key});

  @override
  State createState() => _CombustiblePickerDialogState();
}

class _CombustiblePickerDialogState extends State<CombustiblePickerDialog> {
  String? _selectedCombustible;

  final List<String> tiposCombustible = [
    'Gasolina',
    'Diésel',
    'Gas Natural',
    'Híbrido',
    'Eléctrico',
    'Otros',
  ];

  @override
  void initState() {
    super.initState();
    _selectedCombustible = widget.initialSelected;
  }

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme;
    return AlertDialog(
      title: Text('Selecciona tipo de combustible', style: style.bodyMedium),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(100),
          topRight: Radius.circular(100),
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: tiposCombustible.map((tipo) {
            return RadioListTile<String>(
              title: Text(
                tipo,
                style: style.bodySmall,
              ),
              value: tipo,
              groupValue: _selectedCombustible,
              onChanged: (value) {
                setState(() {
                  _selectedCombustible = value;
                });
              },
            );
          }).toList(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(_selectedCombustible),
          child: const Text('Aceptar'),
        ),
      ],
    );
  }
}
