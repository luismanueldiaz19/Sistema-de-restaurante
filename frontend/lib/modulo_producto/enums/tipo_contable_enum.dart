enum TipoContableEnum {
  inventario('INVENTARIO', 'INVENTARIO'),
  gasto('GASTO', 'GASTO'),
  activoFijo('ACTIVO_FIJO', 'ACTIVO FIJO'),
  servicio('SERVICIO', 'SERVICIO');

  final String value;
  final String label;

  const TipoContableEnum(this.value, this.label);
}
