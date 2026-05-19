import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:animate_do/animate_do.dart';
import 'package:intl/intl.dart';
import 'package:sistema_restaurante/model/asiento_contable_model.dart';
import 'package:sistema_restaurante/palletes/app_colors.dart';
import 'package:sistema_restaurante/providers/auth_provider.dart';
import 'package:sistema_restaurante/providers/configuracion_contable_provider.dart';

class LibroDiarioScreen extends ConsumerStatefulWidget {
  const LibroDiarioScreen({super.key});

  @override
  ConsumerState<LibroDiarioScreen> createState() => _LibroDiarioScreenState();
}

class _LibroDiarioScreenState extends ConsumerState<LibroDiarioScreen> {
  final TextEditingController _searchController = TextEditingController();
  DateTime? _fechaDesde;
  DateTime? _fechaHasta;
  final NumberFormat _currencyFormat = NumberFormat.currency(
    symbol: 'RD\$ ',
    decimalDigits: 2,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAsientos();
    });
  }

  void _loadAsientos() {
    final token = ref.read(authProvider).token;
    if (token != null) {
      final formatter = DateFormat('yyyy-MM-dd');
      final desdeStr = _fechaDesde != null ? formatter.format(_fechaDesde!) : null;
      final hastaStr = _fechaHasta != null ? formatter.format(_fechaHasta!) : null;
      
      ref.read(configuracionContableProvider.notifier).fetchAsientos(
            token,
            fechaDesde: desdeStr,
            fechaHasta: hastaStr,
            buscar: _searchController.text.trim(),
          );
    }
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: _fechaDesde != null && _fechaHasta != null
          ? DateTimeRange(start: _fechaDesde!, end: _fechaHasta!)
          : null,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppColors.azulOscuro,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _fechaDesde = picked.start;
        _fechaHasta = picked.end;
      });
      _loadAsientos();
    }
  }

  void _clearFilters() {
    setState(() {
      _fechaDesde = null;
      _fechaHasta = null;
      _searchController.clear();
    });
    _loadAsientos();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(configuracionContableProvider);
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 900;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Libro Diario General',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: AppColors.azulOscuro,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // 🚀 HEADER BANNER
          FadeInDown(
            duration: const Duration(milliseconds: 250),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              decoration: const BoxDecoration(gradient: AppColors.darkGradient),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'HISTORIAL DE ASIENTOS CONTABLES',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                      color: AppColors.primary.withValues(alpha: 0.9),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Libro Diario General',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Visualiza, audita y filtra todos los movimientos de partida doble generados por las operaciones en tiempo real.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade300,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 🔍 CONTROLES DE BÚSQUEDA Y FILTRADO
          FadeInDown(
            duration: const Duration(milliseconds: 250),
            delay: const Duration(milliseconds: 100),
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: isDesktop
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Campo Buscar
                        Expanded(
                          flex: 3,
                          child: TextField(
                            controller: _searchController,
                            onSubmitted: (_) => _loadAsientos(),
                            decoration: InputDecoration(
                              hintText: 'Buscar por referencia (NCF), glosa...',
                              prefixIcon: const Icon(Icons.search, color: Colors.grey),
                              suffixIcon: _searchController.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear, size: 20),
                                      onPressed: () {
                                        _searchController.clear();
                                        _loadAsientos();
                                      },
                                    )
                                  : null,
                              filled: true,
                              fillColor: Colors.grey.shade100,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Botón Rango de Fechas
                        Expanded(
                          flex: 2,
                          child: OutlinedButton.icon(
                            onPressed: () => _selectDateRange(context),
                            icon: const Icon(Icons.date_range, color: AppColors.azulOscuro),
                            label: Text(
                              _fechaDesde != null && _fechaHasta != null
                                  ? '${DateFormat('dd/MM/yyyy').format(_fechaDesde!)} - ${DateFormat('dd/MM/yyyy').format(_fechaHasta!)}'
                                  : 'Filtrar por Rango de Fecha',
                              style: const TextStyle(
                                color: AppColors.azulOscuro,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              side: BorderSide(color: Colors.grey.shade300),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Botón Limpiar y Buscar
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (_fechaDesde != null ||
                                _fechaHasta != null ||
                                _searchController.text.isNotEmpty)
                              TextButton(
                                onPressed: _clearFilters,
                                child: const Text(
                                  'Limpiar',
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              onPressed: _loadAsientos,
                              icon: const Icon(Icons.search, size: 18),
                              label: const Text('Buscar'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Campo Buscar
                        TextField(
                          controller: _searchController,
                          onSubmitted: (_) => _loadAsientos(),
                          decoration: InputDecoration(
                            hintText: 'Buscar por referencia (NCF), glosa...',
                            prefixIcon: const Icon(Icons.search, color: Colors.grey),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, size: 20),
                                    onPressed: () {
                                      _searchController.clear();
                                      _loadAsientos();
                                    },
                                  )
                                : null,
                            filled: true,
                            fillColor: Colors.grey.shade100,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Botón Rango de Fechas
                        OutlinedButton.icon(
                          onPressed: () => _selectDateRange(context),
                          icon: const Icon(Icons.date_range, color: AppColors.azulOscuro),
                          label: Text(
                            _fechaDesde != null && _fechaHasta != null
                                ? '${DateFormat('dd/MM/yyyy').format(_fechaDesde!)} - ${DateFormat('dd/MM/yyyy').format(_fechaHasta!)}'
                                : 'Filtrar por Rango de Fecha',
                            style: const TextStyle(
                              color: AppColors.azulOscuro,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            side: BorderSide(color: Colors.grey.shade300),
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Botón Limpiar y Buscar
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (_fechaDesde != null ||
                                _fechaHasta != null ||
                                _searchController.text.isNotEmpty)
                              TextButton(
                                onPressed: _clearFilters,
                                child: const Text(
                                  'Limpiar',
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              onPressed: _loadAsientos,
                              icon: const Icon(Icons.search, size: 18),
                              label: const Text('Buscar'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
            ),
          ),

          // 📋 LISTA DE ASIENTOS
          Expanded(
            child: state.isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                : state.errorMessage != null
                    ? Center(
                        child: Text(
                          state.errorMessage!,
                          style: const TextStyle(color: Colors.red, fontSize: 16),
                        ),
                      )
                    : state.asientos.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            itemCount: state.asientos.length,
                            itemBuilder: (context, index) {
                              final asiento = state.asientos[index];
                              return SlideInLeft(
                                duration: const Duration(milliseconds: 250),
                                delay: Duration(milliseconds: index * 50),
                                child: _buildAsientoCard(asiento, isDesktop),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.menu_book_outlined,
            size: 80,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'No se encontraron asientos contables',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Intenta cambiar los filtros o genera transacciones para poblar el diario.',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAsientoCard(AsientoContableModel asiento, bool isDesktop) {
    // Calcular sumas
    double totalDebito = 0.0;
    double totalCredito = 0.0;
    for (var det in asiento.detalles) {
      totalDebito += det.debito;
      totalCredito += det.credito;
    }

    final isBalanced = (totalDebito - totalCredito).abs() <= 0.05;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: ExpansionTile(
          initiallyExpanded: true,
          shape: const Border(),
          backgroundColor: Colors.white,
          collapsedBackgroundColor: Colors.white,
          title: Row(
            children: [
              // Fecha
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.azulOscuro.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_month, color: AppColors.azulOscuro, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      asiento.fecha,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.azulOscuro,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Referencia (ej. NCF)
              if (asiento.referencia != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    asiento.referencia!,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                ),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              asiento.glosa ?? 'Sin descripción',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: asiento.estado == 'Posteado'
                  ? AppColors.success.withValues(alpha: 0.15)
                  : Colors.amber.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              asiento.estado.toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: asiento.estado == 'Posteado' ? AppColors.success : Colors.amber.shade800,
              ),
            ),
          ),
          children: [
            const Divider(height: 1, color: Colors.grey),

            // TABLA DE PARTIDA DOBLE
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Encabezados
                  Row(
                    children: [
                      Expanded(
                        flex: isDesktop ? 3 : 2,
                        child: Text(
                          'CUENTA CONTABLE',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade400,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'DÉBITO (DR)',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade400,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'CRÉDITO (CR)',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade400,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Líneas del asiento
                  ...asiento.detalles.map((det) {
                    final accCode = det.cuenta?.codigo ?? '';
                    final accName = det.cuenta?.nombre ?? 'Cuenta sin nombre';
                    final isDebit = det.debito > 0;

                    return Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Colors.grey.shade100),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            flex: isDesktop ? 3 : 2,
                            child: Padding(
                              padding: EdgeInsets.only(
                                left: isDebit ? 0.0 : 16.0,
                              ),
                              child: Text(
                                '$accCode • $accName',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight:
                                      isDebit ? FontWeight.bold : FontWeight.w500,
                                  color: isDebit
                                      ? AppColors.azulOscuro
                                      : Colors.grey.shade600,
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              det.debito > 0 ? _currencyFormat.format(det.debito) : '-',
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: det.debito > 0 ? AppColors.azulOscuro : Colors.grey.shade400,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              det.credito > 0 ? _currencyFormat.format(det.credito) : '-',
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: det.credito > 0 ? AppColors.primary : Colors.grey.shade400,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),

                  const SizedBox(height: 12),

                  // Footer de Totales del Asiento
                  Row(
                    children: [
                      Expanded(
                        flex: isDesktop ? 3 : 2,
                        child: Row(
                          children: [
                            if (isBalanced)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.success.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.check_circle, color: AppColors.success, size: 14),
                                    SizedBox(width: 4),
                                    Text(
                                      'Cuadrado',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.success,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.red.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.error, color: Colors.red, size: 14),
                                    SizedBox(width: 4),
                                    Text(
                                      'Descuadrado',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.red,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            const SizedBox(width: 8),
                            Text(
                              'TOTAL PARTIDA DOBLE:',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Text(
                          _currencyFormat.format(totalDebito),
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color: AppColors.azulOscuro,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          _currencyFormat.format(totalCredito),
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Usuario creador
                  if (asiento.usuario != null) ...[
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Icon(Icons.person, color: Colors.grey.shade400, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          'Registrado por: ${asiento.usuario!.name}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade500,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
