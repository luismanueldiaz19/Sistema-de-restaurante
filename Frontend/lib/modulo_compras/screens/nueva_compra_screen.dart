import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/compras_provider.dart';
import '../providers/proveedores_provider.dart';
import '../../modulo_producto/providers/producto_provider.dart';
import '../../utils/helpers.dart';
import '../providers/nueva_compra_form_provider.dart';
import '../../facturacion/providers/metodo_pago_provider.dart';

import 'widgets/compra_configuracion_form.dart';
import 'widgets/compra_catalogo_productos.dart';
import 'widgets/compra_carrito_lista.dart';
import 'widgets/compra_panel_totales.dart';

class NuevaCompraScreen extends ConsumerStatefulWidget {
  const NuevaCompraScreen({super.key});

  @override
  ConsumerState<NuevaCompraScreen> createState() => _NuevaCompraScreenState();
}

class _NuevaCompraScreenState extends ConsumerState<NuevaCompraScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(proveedoresProvider.notifier).loadProveedores();
      final token = ref.read(comprasProvider.notifier).token;
      if (token != null) {
        ref.read(productoProvider.notifier).loadProductos(token, silent: true);
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

    if (formState.tipoCompra == 'CONTADO' && formState.metodoPagoId == null) {
      showToast(
        context,
        'Seleccione un método de pago',
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
        'T',
      )[0],
      'tipo_compra': formState.tipoCompra,
      'metodo_pago_id': formState.metodoPagoId,
      'notas': formState.notas,
      // ── IDEMPOTENCIA ─────────────────────────────────────────────────────
      // El mismo UUID se envía en cada reintento del formulario.
      // El backend detecta si ya existe una compra con este key y,
      // de ser así, devuelve la existente sin duplicar ningún registro.
      'idempotency_key': formState.idempotencyKey,
      // ──────────────────────────────────────────────────────────────────────
      'detalles': formState.detalles.map((d) => d.toJson()).toList(),
    };

    final success = await ref.read(comprasProvider.notifier).createCompra(data);
    if (success && mounted) {
      showToast(context, 'Compra registrada con éxito', bgColor: Colors.green);
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
    final isTablet = size.width > 900;

    return Scaffold(
      // backgroundColor: AppColors.light,
      appBar: AppBar(
        title: const Text(
          'Registro de Compras',
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
          if (!isTablet) {
            return _buildMobileLayout();
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // PANEL IZQUIERDO: FORMULARIO CONFIGURACION
              SizedBox(
                width: 360,
                child: Container(
                  margin: const EdgeInsets.all(24),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const SingleChildScrollView(
                    child: CompraConfiguracionForm(),
                  ),
                ),
              ),

              // PANEL CENTRAL: CATÁLOGO PRODUCTOS
              const Expanded(child: CompraCatalogoProductos()),

              // PANEL DERECHO: CARRITO Y TOTALES
              SizedBox(
                width: isTablet ? 340 : 400,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(0, 16, 24, 24),
                  child: Column(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(32),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.03),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: const CompraCarritoLista(),
                        ),
                      ),
                      const SizedBox(height: 20),
                      CompraPanelTotales(onGuardar: _guardarCompra),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const CompraConfiguracionForm(),
                ),
                SizedBox(
                  height: 400, // Alto fijo para catálogo en móvil
                  child: const CompraCatalogoProductos(),
                ),
                Container(
                  margin: const EdgeInsets.all(16),
                  height: 300,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const CompraCarritoLista(),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: CompraPanelTotales(onGuardar: _guardarCompra),
        ),
      ],
    );
  }
}
