import 'package:flutter/material.dart';

class EstadoSelector extends StatefulWidget {
  final String initialValue;
  final Function(String) onChanged;

  const EstadoSelector({
    super.key,
    required this.initialValue,
    required this.onChanged,
  });

  @override
  State<EstadoSelector> createState() => _EstadoSelectorState();
}

class _EstadoSelectorState extends State<EstadoSelector> {
  late String selectedEstado;

  final List<String> estados = [
    "Efectivo",
    "Targeta Credito/Debito",
    "Transferencia",
    "Cheque",
    "Crédito",
    "Otros"
  ];

  @override
  void initState() {
    super.initState();
    selectedEstado = widget.initialValue;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      color: Colors.white,
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedEstado,
          onChanged: (String? newValue) {
            if (newValue != null) {
              setState(() {
                selectedEstado = newValue;
              });
              widget.onChanged(newValue);
            }
          },
          items: estados.map((String estado) {
            return DropdownMenuItem<String>(
              value: estado,
              child: Text(estado),
            );
          }).toList(),
        ),
      ),
    );
  }
}
