import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/compras_provider.dart';
import '../providers/proveedores_provider.dart';
import '../../modulo_producto/providers/producto_provider.dart';
import '../../utils/helpers.dart';
import '../providers/nueva_compra_form_provider.dart';
import '../../../facturacion/providers/metodo_pago_provider.dart';

import 'widgets/compra_configuracion_form.dart';
import 'widgets/gasto_form_detalle.dart';
import 'widgets/compra_carrito_lista.dart';
import 'widgets/compra_panel_totales.dart';

class RegistrarGastoScreen extends ConsumerStatefulWidget {
  const RegistrarGastoScreen({super.key});

  @override
  ConsumerState<RegistrarGastoScreen> createState() =>
      _RegistrarGastoScreenState();
}

class _RegistrarGastoScreenState extends ConsumerState<RegistrarGastoScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(proveedoresProvider.notifier).loadProveedores();
      final token = ref.read(comprasProvider.notifier).token;
      if (token != null) {
        ref
            .read(productoProvider.notifier)
            .loadProductos(token, silent: true, search: '');
      }
      ref.read(metodoPagoProvider).fetchMetodosActivos();
      // Resetear el formulario al entrar
      ref.read(nuevaCompraFormProvider.notifier).clearForm();
    });
  }

  void _guardarCompra() async {
    final formState = ref.read(nuevaCompraFormProvider);

    if (formState.proveedorId == null) {
      showToast(context, 'Seleccione un proveedor', bgColor: Colors.orange);
      return;
    }
    if (formState.numFactura.isEmpty) {
      showToast(context, 'Ingrese número de factura', bgColor: Colors.orange);
      return;
    }
    if (formState.detalles.isEmpty) {
      showToast(
        context,
        'Agregue al menos un producto al carrito',
        bgColor: Colors.orange,
      );
      return;
    }
    if (formState.tipoCompra == 'CREDITO' &&
        formState.fechaVencimiento == null) {
      showToast(
        context,
        'Seleccione fecha de vencimiento',
        bgColor: Colors.orange,
      );
      return;
    }

    final data = {
      'proveedor_id': int.tryParse(formState.proveedorId ?? ''),
      'numero_factura_proveedor': formState.numFactura,
      'ncf': formState.ncf,
      'fecha_compra': formState.fechaCompra.toIso8601String().split('T')[0],
      'fecha_vencimiento': formState.fechaVencimiento?.toIso8601String().split(
        'G',
      )[0],
      'tipo_compra': formState.tipoCompra,
      'notas': formState.notas,
      // ── IDEMPOTENCIA ─────────────────────────────────────────────────────
      // El mismo UUID se envía en cada reintento del formulario.
      // El backend detecta si ya existe una compra con este key y,
      // de ser así, devuelve la existente sin duplicar ningún registro.
      'idempotency_key': formState.idempotencyKey,
      // ──────────────────────────────────────────────────────────────────────
      'detalles': formState.detalles.map((d) => d.toJson()).toList(),
      if (formState.tipoCompra == 'CONTADO')
        'metodo_pago_id': formState.metodoPagoId,
    };

    print(data);

    final success = await ref.read(comprasProvider.notifier).createCompra(data);
    if (success && mounted) {
      showToast(context, 'Gasto registrado con éxito', bgColor: Colors.green);
      // clearForm() genera un nuevo idempotency_key para el próximo formulario
      ref.read(nuevaCompraFormProvider.notifier).clearForm();
      Navigator.pop(context);
    } else if (mounted) {
      showToast(
        context,
        ref.read(comprasProvider).error ?? 'Error al registrar',
        bgColor: Colors.red,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      // backgroundColor: AppColors.light,
      appBar: AppBar(
        title: const Text(
          'Registro de Gastos',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          // if (!isTablet) {
          //   return _buildMobileLayout();
          // }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ⚙️ PANEL IZQUIERDO: CONFIGURACION (320px)
              SizedBox(
                width: 320,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 8, 16),
                  child: SingleChildScrollView(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      // Usamos isCompact: false para que los campos se apilen verticalmente
                      // y quepan bien en una columna de 320px.
                      child: const CompraConfiguracionForm(isCompact: false),
                    ),
                  ),
                ),
              ),

              // 📝 PANEL CENTRAL: GASTO
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
                  child: SingleChildScrollView(child: GastoFormDetalle()),
                ),
              ),

              // 🛒 PANEL DERECHO: CARRITO Y TOTALES (320px)
              SizedBox(
                width: 320,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 16, 16, 16),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: const CompraCarritoLista(),
                        ),
                        const SizedBox(height: 16),
                        CompraPanelTotales(
                          onGuardar: _guardarCompra,
                          textoBoton: 'REGISTRAR GASTO',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
