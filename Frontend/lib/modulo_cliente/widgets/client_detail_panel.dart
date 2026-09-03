import 'package:flutter/material.dart';
import '../../palletes/app_colors.dart';
import '../models/cliente.dart';
import 'client_detail_item.dart';

class ClientDetailPanel extends StatelessWidget {
  final Cliente cliente;

  const ClientDetailPanel({super.key, required this.cliente});

  String _getInitials(String? name) {
    if (name == null || name.trim().isEmpty) return "C";
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) return parts[0].substring(0, 1).toUpperCase();
    return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Banner/Header
          Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.azulOscuro.withValues(alpha: 0.02),
                  AppColors.azulOscuro.withValues(alpha: 0.08),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.azulOscuro,
                  radius: 40,
                  child: Text(
                    _getInitials(cliente.nombre),
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cliente.nombre ?? "Sin nombre",
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppColors.azulOscuro,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: (cliente.activo == true)
                              ? Colors.green.withValues(alpha: 0.15)
                              : Colors.red.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: (cliente.activo == true)
                                ? Colors.green.withValues(alpha: 0.3)
                                : Colors.red.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          (cliente.activo == true) ? "Activo" : "Inactivo",
                          style: TextStyle(
                            color: (cliente.activo == true)
                                ? Colors.green.shade700
                                : Colors.red.shade700,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Details Grid
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle(
                    Icons.person_outline,
                    "Información General",
                  ),
                  const SizedBox(height: 20),
                  _buildInfoGrid([
                    ClientDetailItem(
                      icon: Icons.badge_outlined,
                      label: "RNC/Cédula",
                      value: cliente.rncCedula ?? "N/A",
                    ),
                    ClientDetailItem(
                      icon: Icons.email_outlined,
                      label: "Email",
                      value: cliente.email ?? "N/A",
                    ),
                    ClientDetailItem(
                      icon: Icons.phone_outlined,
                      label: "Teléfono",
                      value: cliente.telefono ?? "N/A",
                    ),
                    ClientDetailItem(
                      icon: Icons.location_on_outlined,
                      label: "Dirección",
                      value: cliente.direccion ?? "N/A",
                    ),
                  ]),
                  const SizedBox(height: 40),
                  _buildSectionTitle(
                    Icons.account_balance_wallet_outlined,
                    "Finanzas y Crédito",
                  ),
                  const SizedBox(height: 20),
                  _buildInfoGrid([
                    ClientDetailItem(
                      icon: Icons.category_outlined,
                      label: "Tipo de Cliente",
                      value: cliente.tipoCliente ?? "N/A",
                    ),
                    ClientDetailItem(
                      icon: Icons.credit_card_outlined,
                      label: "Límite de Crédito",
                      value:
                          "\$${cliente.limiteCredito?.toStringAsFixed(2) ?? '0.00'}",
                    ),
                    ClientDetailItem(
                      icon: Icons.attach_money_rounded,
                      label: "Saldo Actual",
                      value:
                          "\$${cliente.saldoActual?.toStringAsFixed(2) ?? '0.00'}",
                      isHighlight: true,
                    ),
                    ClientDetailItem(
                      icon: Icons.timer_outlined,
                      label: "Días de Crédito",
                      value: "${cliente.diasCredito ?? 0} días",
                    ),
                  ]),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(IconData icon, String title) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.azulOscuro.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.azulOscuro, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.azulOscuro,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoGrid(List<Widget> children) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Wrap(
          spacing: 20,
          runSpacing: 20,
          children: children
              .map(
                (w) =>
                    SizedBox(width: (constraints.maxWidth / 2) - 10, child: w),
              )
              .toList(),
        );
      },
    );
  }
}
