import 'package:flutter/material.dart';

class CatalogoFieldConfig {
  final String key;
  final String label;
  final bool isNumber;
  final String? initialValue;

  CatalogoFieldConfig({
    required this.key,
    required this.label,
    this.isNumber = false,
    this.initialValue,
  });
}

class CatalogoFormDialog extends StatefulWidget {
  final String title;
  final List<CatalogoFieldConfig> fields;
  final Function(Map<String, dynamic>) onSubmit;

  const CatalogoFormDialog({
    Key? key,
    required this.title,
    required this.fields,
    required this.onSubmit,
  }) : super(key: key);

  @override
  _CatalogoFormDialogState createState() => _CatalogoFormDialogState();
}

class _CatalogoFormDialogState extends State<CatalogoFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, dynamic> _formData = {};
  bool _activo = true;

  @override
  void initState() {
    super.initState();
    for (var field in widget.fields) {
      _formData[field.key] = field.initialValue ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ...widget.fields.map((field) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: TextFormField(
                    initialValue: _formData[field.key]?.toString(),
                    decoration: InputDecoration(
                      labelText: field.label,
                      border: const OutlineInputBorder(),
                    ),
                    keyboardType: field.isNumber ? TextInputType.number : TextInputType.text,
                    validator: (val) {
                      if (val == null || val.isEmpty) {
                        return 'Este campo es requerido';
                      }
                      return null;
                    },
                    onSaved: (val) {
                      if (field.isNumber) {
                        _formData[field.key] = double.tryParse(val!) ?? 0;
                      } else {
                        _formData[field.key] = val;
                      }
                    },
                  ),
                );
              }).toList(),
              SwitchListTile(
                title: const Text('Activo'),
                value: _activo,
                onChanged: (val) {
                  setState(() => _activo = val);
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              _formKey.currentState!.save();
              _formData['activo'] = _activo;
              widget.onSubmit(_formData);
              Navigator.pop(context);
            }
          },
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
