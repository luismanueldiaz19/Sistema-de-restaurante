class ResponsiveUtils {
  /// Devuelve la cantidad de columnas para un grid basándose en el ancho de la pantalla
  static int getGridCrossAxisCount(double width) {
    if (width >= 1300) {
      return 9; // Desktop grande
    } else if (width >= 1100) {
      return 8; // Desktop normal / Tablet horizontal
    } else if (width >= 900) {
      return 7; // Desktop normal / Tablet horizontal
    } else if (width >= 700) {
      return 6; // Tablet pequeña
    } else if (width >= 650) {
      return 5; // Phablets / Móviles en horizontal
    } else if (width >= 380) {
      return 4; // Móviles estándar/grandes
    }
    return 3; // Por defecto para móviles pequeños (< 380px)
  }
}
