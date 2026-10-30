import 'package:flutter/material.dart';
import '../../model/asiento_contable_model.dart';
import '../../palletes/app_colors.dart';
import '../../utils/formatter_number.dart';

class AsientoDiarioCard extends StatelessWidget {
  final AsientoContableModel asiento;
  final bool isExpanded;
  final VoidCallback onToggle;

  const AsientoDiarioCard({
    super.key,
    required this.asiento,
    required this.isExpanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    double totalDebito = 0;
    double totalCredito = 0;
    for (final det in asiento.detalles) {
      totalDebito += det.debito;
      totalCredito += det.credito;
    }
    final isBalanced = (totalDebito - totalCredito).abs() <= 0.05;
    final isPosted = asiento.estado.toLowerCase() == 'posteado';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isBalanced ? Colors.grey.shade200 : Colors.red.shade200,
        ),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.vertical(
              top: const Radius.circular(10),
              bottom: Radius.circular(isExpanded ? 0 : 10),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_down_rounded
                        : Icons.keyboard_arrow_right_rounded,
                    size: 18,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.azulOscuro.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      asiento.fecha,
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontFamily: 'Consolas',
                        fontWeight: FontWeight.w700,
                        color: AppColors.azulOscuro,
                      ),
                    ),
                  ),
                  if (asiento.referencia != null &&
                      asiento.referencia!.trim().isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        asiento.referencia!,
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontFamily: 'Consolas',
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      asiento.glosa ?? 'Asiento contable #${asiento.id}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.azulOscuro,
                      ),
                    ),
                  ),
                  if (asiento.usuario != null) ...[
                    const SizedBox(width: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.person_outline_rounded,
                          size: 13,
                          color: Colors.grey.shade500,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          asiento.usuario!.name ?? 'Usuario',
                          style: TextStyle(
                            fontSize: 10.5,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(width: 10),
                  Text(
                    FormatterNumber.formatCurrency(totalDebito),
                    style: const TextStyle(
                      fontSize: 12,
                      fontFamily: 'Consolas',
                      fontWeight: FontWeight.w800,
                      color: AppColors.azulOscuro,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2.5,
                    ),
                    decoration: BoxDecoration(
                      color: (isBalanced ? Colors.green : Colors.red)
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      isBalanced ? 'CUADRADO' : 'DESCUADRADO',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: isBalanced
                            ? Colors.green.shade800
                            : Colors.red.shade800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2.5,
                    ),
                    decoration: BoxDecoration(
                      color: (isPosted ? Colors.teal : Colors.amber).withValues(
                        alpha: 0.12,
                      ),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      asiento.estado.toUpperCase(),
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: isPosted
                            ? Colors.teal.shade800
                            : Colors.amber.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded) ...[
            Divider(height: 1, color: Colors.grey.shade200),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              color: Colors.grey.shade50,
              child: Row(
                children: [
                  Expanded(
                    flex: 5,
                    child: Text(
                      'CUENTA CONTABLE',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 130,
                    child: Text(
                      'DÉBITO (DR)',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 130,
                    child: Text(
                      'CRÉDITO (CR)',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            ...asiento.detalles.map((det) {
              final isDebit = det.debito > 0;
              final code = det.cuenta?.codigo ?? '';
              final name = det.cuenta?.nombre ?? 'Cuenta #${det.cuentaId}';
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 5.5,
                ),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade100),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 5,
                      child: Padding(
                        padding: EdgeInsets.only(left: isDebit ? 0 : 14),
                        child: Row(
                          children: [
                            if (code.isNotEmpty) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                  vertical: 1.5,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  code,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontFamily: 'Consolas',
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.azulOscuro,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                            ],
                            Expanded(
                              child: Text(
                                name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: isDebit
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: isDebit
                                      ? AppColors.azulOscuro
                                      : Colors.grey.shade700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 130,
                      child: Text(
                        det.debito > 0
                            ? FormatterNumber.formatCurrency(det.debito)
                            : '—',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontFamily: 'Consolas',
                          fontWeight: det.debito > 0
                              ? FontWeight.w700
                              : FontWeight.normal,
                          color: det.debito > 0
                              ? AppColors.azulOscuro
                              : Colors.grey.shade400,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 130,
                      child: Text(
                        det.credito > 0
                            ? FormatterNumber.formatCurrency(det.credito)
                            : '—',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontFamily: 'Consolas',
                          fontWeight: det.credito > 0
                              ? FontWeight.w700
                              : FontWeight.normal,
                          color: det.credito > 0
                              ? AppColors.primaryDark
                              : Colors.grey.shade400,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(10),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 5,
                    child: Text(
                      'TOTAL PARTIDA DOBLE (${asiento.detalles.length} líneas)',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 130,
                    child: Text(
                      FormatterNumber.formatCurrency(totalDebito),
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontFamily: 'Consolas',
                        fontWeight: FontWeight.w900,
                        color: AppColors.azulOscuro,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 130,
                    child: Text(
                      FormatterNumber.formatCurrency(totalCredito),
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontFamily: 'Consolas',
                        fontWeight: FontWeight.w900,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

