import 'package:flutter/material.dart';

class ClienteSearch extends StatelessWidget {
  final Function(String) onChanged;

  const ClienteSearch({super.key, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return TextField(
      decoration: const InputDecoration(
        labelText: 'Buscar cliente',
        prefixIcon: Icon(Icons.search),
        border: OutlineInputBorder(),
      ),
      onChanged: onChanged,
    );
  }
}
