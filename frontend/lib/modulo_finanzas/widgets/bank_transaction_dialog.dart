import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/bank_provider.dart';
import '../../palletes/app_colors.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_button.dart';

class BankTransactionDialog extends ConsumerStatefulWidget {
  final int accountId;

  const BankTransactionDialog({super.key, required this.accountId});

  @override
  ConsumerState<BankTransactionDialog> createState() =>
      _BankTransactionDialogState();
}

class _BankTransactionDialogState extends ConsumerState<BankTransactionDialog> {
  final _formKey = GlobalKey<FormState>();
  String _selectedType = 'deposit';
  DateTime _selectedDate = DateTime.now();
  final TextEditingController _amountCtrl = TextEditingController();
  final TextEditingController _referenceCtrl = TextEditingController();
  final TextEditingController _descriptionCtrl = TextEditingController();

  bool _isLoading = false;

  void _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    final token = ref.read(authProvider).token;
    if (token == null) return;

    setState(() => _isLoading = true);

    final data = {
      'bank_account_id': widget.accountId,
      'date': DateFormat('yyyy-MM-dd').format(_selectedDate),
      'type': _selectedType,
      'amount': double.tryParse(_amountCtrl.text) ?? 0,
      'reference': _referenceCtrl.text,
      'description': _descriptionCtrl.text,
    };

    try {
      await ref.read(bankProvider.notifier).registerTransaction(token, data);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Registrar Transacción',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.azulOscuro,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const Divider(),
                const SizedBox(height: 16),

                // Tipo de Transacción con estilo similar a CustomTextField
                Text(
                  'Tipo de Transacción',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedType,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 15,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppColors.azulOscuro,
                        width: 1.5,
                      ),
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'deposit', child: Text('Depósito')),
                    DropdownMenuItem(
                      value: 'withdrawal',
                      child: Text('Retiro'),
                    ),
                    DropdownMenuItem(
                      value: 'fee',
                      child: Text('Cargo/Comisión'),
                    ),
                    DropdownMenuItem(value: 'interest', child: Text('Interés')),
                  ],
                  onChanged: (v) => setState(() => _selectedType = v!),
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: CustomTextField(
                        controller: _amountCtrl,
                        label: 'Monto',
                        hintText: 'Ej: 1500.00',
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*\.?\d{0,2}'),
                          ),
                        ],
                        prefixIcon: Icons.attach_money,
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Requerido';
                          if (double.tryParse(v) == null)
                            return 'Monto inválido';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _selectedDate,
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );
                          if (date != null) {
                            setState(() => _selectedDate = date);
                          }
                        },
                        child: AbsorbPointer(
                          child: CustomTextField(
                            controller: TextEditingController(
                              text: DateFormat(
                                'dd/MM/yyyy',
                              ).format(_selectedDate),
                            ),
                            label: 'Fecha',
                            readOnly: true,
                            suffixIcon: Icons.calendar_today,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                CustomTextField(
                  controller: _referenceCtrl,
                  label: 'Referencia (Opcional)',
                  hintText: 'Ej: DEP-00123',
                ),
                const SizedBox(height: 16),

                CustomTextField(
                  controller: _descriptionCtrl,
                  label: 'Descripción / Concepto',
                  hintText: 'Añade una descripción',
                  maxLines: 3,
                ),

                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    CustomButton(
                      title: 'Cancelar',
                      onPressed: () => Navigator.pop(context),
                      isFlat: true,
                      width: 120,
                      backgroundColor: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 16),
                    CustomButton(
                      title: 'Guardar',
                      onPressed: _isLoading ? null : _guardar,
                      isLoading: _isLoading,
                      width: 150,
                      backgroundColor: AppColors.primary,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
