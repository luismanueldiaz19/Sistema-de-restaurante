import 'package:flutter/material.dart';
import '../../palletes/app_colors.dart';
import '../../modulo_cliente/models/cliente.dart';
import '../../model/comprobante.dart';

class PanelConfiguracion extends StatefulWidget {
  final Cliente? cliente;
  final Comprobante? comprobante;
  final List<Comprobante> comprobantes;
  final String tipoFactura;
  final int diasCredito;
  final String nota;
  final VoidCallback onSelectCliente;
  final Function(Comprobante?) onSelectComprobante;
  final Function(String) onCambiarTipo;
  final Function(int) onCambiarDias;
  final Function(String) onCambiarNota;

  const PanelConfiguracion({
    super.key,
    required this.cliente,
    required this.comprobante,
    required this.comprobantes,
    required this.tipoFactura,
    required this.diasCredito,
    required this.nota,
    required this.onSelectCliente,
    required this.onSelectComprobante,
    required this.onCambiarTipo,
    required this.onCambiarDias,
    required this.onCambiarNota,
  });

  @override
  State<PanelConfiguracion> createState() => _PanelConfiguracionState();
}

class _PanelConfiguracionState extends State<PanelConfiguracion> {
  late TextEditingController _notaController;

  @override
  void initState() {
    super.initState();
    _notaController = TextEditingController(text: widget.nota);
  }

  @override
  void didUpdateWidget(PanelConfiguracion oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.nota.isEmpty && oldWidget.nota.isNotEmpty) {
      _notaController.clear();
    }
  }

  @override
  void dispose() {
    _notaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 18,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'CONFIGURACIÓN',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: AppColors.secondary,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Selector de Cliente
          const _Label(text: 'CLIENTE'),
          const SizedBox(height: 6),
          InkWell(
            onTap: widget.onSelectCliente,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: widget.cliente == null
                      ? Colors.grey.shade300
                      : AppColors.primary.withValues(alpha: 0.3),
                ),
                boxShadow: [
                  if (widget.cliente != null)
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: widget.cliente == null
                          ? Colors.grey.shade100
                          : AppColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      widget.cliente == null
                          ? Icons.person_add_alt_1_outlined
                          : Icons.person,
                      color: widget.cliente == null
                          ? Colors.grey.shade500
                          : AppColors.primary,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.cliente?.nombre ?? 'Seleccionar Cliente',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 12.5,
                            color: widget.cliente == null
                                ? Colors.grey.shade600
                                : AppColors.secondary,
                          ),
                        ),
                        if (widget.cliente != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            widget.cliente!.rncCedula ?? 'Sin identificación',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade500,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Icon(
                    Icons.keyboard_arrow_right,
                    color: Colors.grey.shade400,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 18),

          // Tipo de Factura (Contado/Crédito)
          const _Label(text: 'CONDICIÓN DE PAGO'),
          const SizedBox(height: 6),
          Row(
            children: [
              _buildTipoOption(
                label: 'Contado',
                isSelected: widget.tipoFactura == 'contado',
                onTap: () => widget.onCambiarTipo('contado'),
              ),
              if (widget.cliente != null &&
                  (widget.cliente?.diasCredito ?? 0) > 0) ...[
                const SizedBox(width: 10),
                _buildTipoOption(
                  label: 'Crédito',
                  isSelected: widget.tipoFactura == 'credito',
                  onTap: () => widget.onCambiarTipo('credito'),
                ),
              ],
            ],
          ),

          if (widget.tipoFactura == 'credito') ...[
            const SizedBox(height: 18),
            const _Label(text: 'DÍAS DE CRÉDITO'),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: TextFormField(
                key: ValueKey(widget.cliente?.id),
                initialValue: widget.diasCredito.toString(),
                keyboardType: TextInputType.number,
                style: const TextStyle(fontSize: 13),
                decoration: const InputDecoration(
                  hintText: 'Ej. 30',
                  border: InputBorder.none,
                  hintStyle: TextStyle(fontSize: 13),
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 9),
                ),
                onChanged: (v) => widget.onCambiarDias(int.tryParse(v) ?? 0),
              ),
            ),
          ],

          const SizedBox(height: 18),

          // Notas de la Factura
          const _Label(text: 'NOTAS / DIRECCIÓN'),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: TextFormField(
              controller: _notaController,
              maxLines: 2,
              style: const TextStyle(fontSize: 12.5),
              decoration: const InputDecoration(
                hintText: 'Ej. Dirección de entrega, indicaciones...',
                border: InputBorder.none,
                hintStyle: TextStyle(fontSize: 12.5),
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 9),
              ),
              onChanged: widget.onCambiarNota,
            ),
          ),

          const SizedBox(height: 18),

          // Selector de Comprobante (100% legible sin cortes)
          const _Label(text: 'TIPO DE COMPROBANTE'),
          const SizedBox(height: 6),
          _buildComprobanteSelector(),
        ],
      ),
    );
  }

  String _hintFiscal(String tipoRaw) {
    final t = tipoRaw.replaceAll(RegExp(r'[^0-9]'), '');
    switch (t) {
      case '31':
        return 'Deduce costos/ITBIS • Requiere RNC o Cédula';
      case '32':
        return 'Consumidor final / Público general';
      case '44':
        return 'Zonas francas, embajadas o leyes de exención';
      case '45':
        return 'Entidades del Estado • Requiere RNC';
      case '46':
        return 'Bienes o servicios exportados';
      default:
        return 'Comprobante fiscal DGII';
    }
  }

  Widget _buildComprobanteSelector() {
    final selected = widget.comprobante;

    return PopupMenuButton<Comprobante>(
      tooltip: 'Seleccionar tipo de comprobante',
      position: PopupMenuPosition.under,
      constraints: const BoxConstraints(minWidth: 330, maxWidth: 370),
      color: Colors.white,
      surfaceTintColor: Colors.white,
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      onSelected: widget.onSelectComprobante,
      itemBuilder: (context) => widget.comprobantes.map((c) {
        final isSelected = selected?.id == c.id;
        final codigo = '${c.prefijo}${c.tipo}';
        return PopupMenuItem<Comprobante>(
          value: c,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary.withValues(alpha: 0.08)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.secondary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    codigo,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: isSelected ? Colors.white : AppColors.secondary,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        c.nombre,
                        softWrap: true,
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.2,
                          fontWeight: isSelected
                              ? FontWeight.w800
                              : FontWeight.w600,
                          color: AppColors.secondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _hintFiscal(c.tipo),
                        softWrap: true,
                        style: TextStyle(
                          fontSize: 10.5,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
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
      }).toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected != null
                ? AppColors.primary.withValues(alpha: 0.35)
                : Colors.grey.shade300,
          ),
        ),
        child: Row(
          children: [
            if (selected != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${selected.prefijo}${selected.tipo}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryDark,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  selected.nombre,
                  softWrap: true,
                  style: const TextStyle(
                    fontSize: 11.5,
                    height: 1.2,
                    fontWeight: FontWeight.w700,
                    color: AppColors.secondary,
                  ),
                ),
              ),
            ] else
              const Expanded(
                child: Text(
                  'Seleccionar comprobante...',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              color: Colors.grey.shade600,
              size: 19,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTipoOption({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? AppColors.primary : Colors.grey.shade300,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey.shade700,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 10.5,
        fontWeight: FontWeight.bold,
        color: Colors.grey.shade400,
        letterSpacing: 0.5,
      ),
    );
  }
}
