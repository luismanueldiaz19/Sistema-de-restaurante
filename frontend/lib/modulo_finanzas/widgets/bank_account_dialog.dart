import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../model/banco_models.dart';
import '../../providers/auth_provider.dart';
import '../../providers/bank_provider.dart';
import '../../providers/configuracion_contable_provider.dart';
import '../../palletes/app_colors.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_button.dart';

class BankAccountDialog extends ConsumerStatefulWidget {
  final BankAccountModel? account;
  const BankAccountDialog({super.key, this.account});

  @override
  ConsumerState<BankAccountDialog> createState() => _BankAccountDialogState();
}

class _BankAccountDialogState extends ConsumerState<BankAccountDialog> {
  final _formKey = GlobalKey<FormState>();
  int? _selectedBankId;
  int? _selectedAccountingAccountId;
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _accountNumberCtrl = TextEditingController();
  final TextEditingController _currencyCtrl = TextEditingController(
    text: 'DOP',
  );
  final TextEditingController _initialBalanceCtrl = TextEditingController(
    text: '0',
  );

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final token = ref.read(authProvider).token;
      if (token != null) {
        ref.read(configuracionContableProvider.notifier).loadAllData(token);
      }
    });

    if (widget.account != null) {
      _selectedBankId = widget.account!.bankId;
      _nameCtrl.text = widget.account!.name;
      _accountNumberCtrl.text = widget.account!.accountNumber;
      _currencyCtrl.text = widget.account!.currency;
      _initialBalanceCtrl.text = widget.account!.currentBalance.toString();
      _selectedAccountingAccountId = widget.account!.accountingAccountId;
    }
  }

  void _guardar() async {
    if (!_formKey.currentState!.validate() || _selectedBankId == null) {
      if (_selectedBankId == null && mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Seleccione un banco')));
      }
      return;
    }

    final token = ref.read(authProvider).token;
    if (token == null) return;

    setState(() => _isLoading = true);

    final data = {
      'bank_id': _selectedBankId,
      'name': _nameCtrl.text,
      'account_number': _accountNumberCtrl.text,
      'currency': _currencyCtrl.text,
      'current_balance': double.tryParse(_initialBalanceCtrl.text) ?? 0,
      'accounting_account_id': _selectedAccountingAccountId,
      'is_active': true,
    };

    try {
      if (widget.account == null) {
        await ref.read(bankProvider.notifier).createAccount(token, data);
      } else {
        await ref
            .read(bankProvider.notifier)
            .updateAccount(token, widget.account!.id, data);
      }
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
    final state = ref.watch(bankProvider);
    final contableState = ref.watch(configuracionContableProvider);

    // Encuentra la cuenta principal "ACTIVOS CORRIENTES"
    final bancoParent = contableState.catalogoCuentasCompleto
        .where((c) => c.nombre.toUpperCase().trim() == 'ACTIVOS CORRIENTES')
        .firstOrNull;

    List<int> descendientesIds = [];
    if (bancoParent != null) {
      void buscarHijos(int id) {
        final hijos = contableState.catalogoCuentasCompleto
            .where((c) => c.padreId == id)
            .toList();
        for (var h in hijos) {
          descendientesIds.add(h.id);
          buscarHijos(h.id);
        }
      }

      buscarHijos(bancoParent.id);
    }

    // Filtrar cuentas de banco (descendientes de BANCOS que permiten movimiento)
    final cuentasBancos = contableState.catalogoCuentasCompleto
        .where((c) => descendientesIds.contains(c.id) && c.permiteMovimiento)
        .toList();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 550,
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
                    Text(
                      widget.account == null
                          ? 'Nueva Cuenta Bancaria'
                          : 'Editar Cuenta Bancaria',
                      style: const TextStyle(
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

                Text(
                  'Banco',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<int>(
                  value: _selectedBankId,
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
                  items: state.banks
                      .map(
                        (b) =>
                            DropdownMenuItem(value: b.id, child: Text(b.name)),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => _selectedBankId = v),
                ),
                const SizedBox(height: 16),

                CustomTextField(
                  controller: _nameCtrl,
                  label: 'Nombre de la cuenta',
                  hintText: 'Ej: Corriente Banreservas',
                  validator: (v) => v!.isEmpty ? 'Requerido' : null,
                ),
                const SizedBox(height: 16),

                CustomTextField(
                  controller: _accountNumberCtrl,
                  label: 'Número de Cuenta',
                  hintText: 'Ej: 987654321',
                  keyboardType: TextInputType.number,
                  validator: (v) => v!.isEmpty ? 'Requerido' : null,
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: CustomTextField(
                        controller: _currencyCtrl,
                        label: 'Moneda',
                        hintText: 'DOP, USD',
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: CustomTextField(
                        controller: _initialBalanceCtrl,
                        label: widget.account == null
                            ? 'Balance Inicial'
                            : 'Balance Actual',
                        hintText: '0.00',
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
                          if (v != null &&
                              v.isNotEmpty &&
                              double.tryParse(v) == null) {
                            return 'Inválido';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                Text(
                  'Cuenta Contable Asociada (Opcional)',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<int>(
                  value: _selectedAccountingAccountId,
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
                  items: cuentasBancos
                      .map(
                        (c) => DropdownMenuItem(
                          value: c.id,
                          child: Text('${c.codigo} - ${c.nombre}'),
                        ),
                      )
                      .toList(),
                  onChanged: (v) =>
                      setState(() => _selectedAccountingAccountId = v),
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
                      title: widget.account == null ? 'Guardar' : 'Actualizar',
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
