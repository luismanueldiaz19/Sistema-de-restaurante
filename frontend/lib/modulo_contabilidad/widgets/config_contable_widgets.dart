import 'package:flutter/material.dart';
import '../../model/catalogo_cuenta_model.dart';
import '../../model/configuracion_contable_model.dart';
import '../../palletes/app_colors.dart';
import '../../widgets/custom_empty_state.dart';
import '../../widgets/custom_text_field.dart';

String configContableHelperText(String key) {
  switch (key) {
    case 'venta_efectivo_debe':
      return 'Activo que registra el efectivo recaudado en ventas del día (ej. Caja General).';
    case 'venta_credito_debe':
      return 'Activo que controla saldos pendientes por cobrar a clientes a crédito.';
    case 'venta_haber':
      return 'Ingresos operativos donde se acumula la facturación de comidas y bebidas.';
    case 'venta_itbis_haber':
      return 'Pasivo corriente que acumula el ITBIS cobrado al cliente para declarar a DGII.';
    case 'compra_inventario_debe':
      return 'Activo realizable que debita materia prima e insumos comprados.';
    case 'compra_proveedor_haber':
      return 'Pasivo que registra las obligaciones comerciales con proveedores.';
    case 'compra_itbis_debe':
      return 'Cuenta que registra el ITBIS pagado en compras para compensar.';
    case 'nomina_gasto_debe':
      return 'Gasto operativo para acumular el costo de sueldos pagados al personal.';
    case 'nomina_pago_haber':
      return 'Cuenta de caja o banco desde donde egresan los salarios netos.';
    default:
      return 'Regla de contabilización automática por partida doble.';
  }
}

class ConfigContableRuleRow extends StatelessWidget {
  final ConfiguracionContableModel config;
  final CatalogoCuentaModel? selectedAccount;
  final bool isModified;
  final VoidCallback onSelectTap;

  const ConfigContableRuleRow({
    super.key,
    required this.config,
    required this.selectedAccount,
    required this.isModified,
    required this.onSelectTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDebit = config.clave.endsWith('_debe');
    final natureColor = isDebit
        ? Colors.green.shade700
        : Colors.indigo.shade700;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isModified
            ? AppColors.primary.withValues(alpha: 0.04)
            : Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 96,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: natureColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isDebit
                          ? Icons.north_east_rounded
                          : Icons.south_west_rounded,
                      size: 12,
                      color: natureColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isDebit ? 'DÉBITO' : 'CRÉDITO',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        color: natureColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            flex: 5,
            child: Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          config.nombre,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.azulOscuro,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          config.clave,
                          style: TextStyle(
                            fontSize: 9.5,
                            fontFamily: 'Consolas',
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                      if (isModified) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 1.5,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'MODIFICADO',
                            style: TextStyle(
                              fontSize: 8.5,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    configContableHelperText(config.clave),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            flex: 4,
            child: InkWell(
              onTap: onSelectTap,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: selectedAccount != null
                      ? Colors.grey.shade50
                      : Colors.orange.shade50.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isModified
                        ? AppColors.primary
                        : (selectedAccount != null
                              ? Colors.grey.shade300
                              : Colors.orange.shade200),
                  ),
                ),
                child: Row(
                  children: [
                    if (selectedAccount != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.azulOscuro.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          selectedAccount!.codigo,
                          style: const TextStyle(
                            fontSize: 10.5,
                            fontFamily: 'Consolas',
                            fontWeight: FontWeight.w800,
                            color: AppColors.azulOscuro,
                          ),
                        ),
                      ),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Text(
                          selectedAccount!.nombre,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.azulOscuro,
                          ),
                        ),
                      ),
                    ] else
                      Expanded(
                        child: Text(
                          'Sin asignar (Seleccionar cuenta...)',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontStyle: FontStyle.italic,
                            color: Colors.orange.shade800,
                          ),
                        ),
                      ),
                    const SizedBox(width: 6),
                    Icon(
                      Icons.unfold_more_rounded,
                      size: 16,
                      color: Colors.grey.shade600,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ConfigCuentaSelectorDialog extends StatefulWidget {
  final List<CatalogoCuentaModel> accounts;
  final int? currentAccountId;
  final String configName;
  final ValueChanged<int?> onSelected;

  const ConfigCuentaSelectorDialog({
    super.key,
    required this.accounts,
    required this.currentAccountId,
    required this.configName,
    required this.onSelected,
  });

  @override
  State<ConfigCuentaSelectorDialog> createState() =>
      _ConfigCuentaSelectorDialogState();
}

class _ConfigCuentaSelectorDialogState
    extends State<ConfigCuentaSelectorDialog> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final q = _query.trim().toLowerCase();
    final filtered = widget.accounts.where((acc) {
      if (q.isEmpty) return true;
      return acc.codigo.toLowerCase().contains(q) ||
          acc.nombre.toLowerCase().contains(q) ||
          acc.tipo.toLowerCase().contains(q);
    }).toList();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 480,
        constraints: const BoxConstraints(maxHeight: 500),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.account_tree_outlined,
                  size: 18,
                  color: AppColors.azulOscuro,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Asignar Cuenta Transaccional',
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.azulOscuro,
                        ),
                      ),
                      Text(
                        widget.configName,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, size: 18),
                ),
              ],
            ),
            const SizedBox(height: 10),
            CustomTextField(
              label: '',
              hintText: 'Filtrar por código (1.1.01), nombre o tipo...',
              prefixIcon: Icons.search_rounded,
              onChanged: (v) => setState(() => _query = v),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: filtered.isEmpty
                  ? const CustomEmptyState(
                      title: 'No se encontraron cuentas transaccionales',
                    )
                  : Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade200),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ListView.separated(
                        itemCount: filtered.length,
                        separatorBuilder: (_, _) =>
                            Divider(height: 1, color: Colors.grey.shade100),
                        itemBuilder: (_, i) {
                          final acc = filtered[i];
                          final isSelected = widget.currentAccountId == acc.id;
                          return InkWell(
                            onTap: () {
                              widget.onSelected(acc.id);
                              Navigator.pop(context);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                              color: isSelected
                                  ? AppColors.primary.withValues(alpha: 0.08)
                                  : Colors.white,
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? AppColors.primary
                                          : Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      acc.codigo,
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        fontFamily: 'Consolas',
                                        fontWeight: FontWeight.w700,
                                        color: isSelected
                                            ? Colors.white
                                            : AppColors.azulOscuro,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      acc.nombre,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.azulOscuro,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    acc.tipo,
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                                  if (isSelected) ...[
                                    const SizedBox(width: 6),
                                    const Icon(
                                      Icons.check_circle_rounded,
                                      size: 16,
                                      color: AppColors.primary,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton.icon(
                  onPressed: () {
                    widget.onSelected(null);
                    Navigator.pop(context);
                  },
                  icon: const Icon(
                    Icons.link_off_rounded,
                    size: 15,
                    color: AppColors.danger,
                  ),
                  label: const Text(
                    'Quitar asignación',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.danger,
                    ),
                  ),
                ),
                OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cerrar', style: TextStyle(fontSize: 11.5)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

