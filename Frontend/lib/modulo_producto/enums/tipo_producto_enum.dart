enum TipoProductoEnum {
  producto('PRODUCTO', 'PRODUCTO'),
  servicio('SERVICIO', 'SERVICIO'),
  combo('COMBO', 'COMBO'),
  plato('PLATO', 'PLATO'),
  materiaPrima('MATERIA_PRIMA', 'MATERIA PRIMA');

  final String value;
  final String label;

  const TipoProductoEnum(this.value, this.label);
}
