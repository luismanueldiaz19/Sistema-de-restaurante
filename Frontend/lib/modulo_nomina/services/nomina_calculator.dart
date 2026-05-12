class NominaCalculator {
  // Porcentajes TSS (Empleado)
  static const double sfsRate = 0.0304; // 3.04%
  static const double afpRate = 0.0287; // 2.87%

  // Topes Salariales TSS (Referenciales)
  static const double topeSFS = 187620.00; // 10 salarios mínimos aprox.
  static const double topeAFP = 375240.00; // 20 salarios mínimos aprox.

  /// Calcula la retención de SFS (Seguro Familiar de Salud)
  static double calculateSFS(double salarioBruto) {
    double base = salarioBruto > topeSFS ? topeSFS : salarioBruto;
    return base * sfsRate;
  }

  /// Calcula la retención de AFP (Fondo de Pensiones)
  static double calculateAFP(double salarioBruto) {
    double base = salarioBruto > topeAFP ? topeAFP : salarioBruto;
    return base * afpRate;
  }

  /// Calcula el ISR (Impuesto Sobre la Renta) mensual
  static double calculateISR(double salarioBruto, double afp, double sfs) {
    double rentaGravable = salarioBruto - afp - sfs;
    
    // Escala Impositiva Mensual DGII (2024)
    if (rentaGravable <= 34685.00) {
      return 0.0;
    } else if (rentaGravable <= 52027.42) {
      return (rentaGravable - 34685.00) * 0.15;
    } else if (rentaGravable <= 72260.25) {
      return 2601.36 + ((rentaGravable - 52027.42) * 0.20);
    } else {
      return 6648.00 + ((rentaGravable - 72260.25) * 0.25);
    }
  }

  /// Realiza el cálculo completo para un empleado ajustado a la frecuencia
  static Map<String, double> calculateAll(
    double salarioMensualBase, {
    String frecuencia = 'Mensual',
    double otrosDescuentos = 0.0,
    double horasExtras = 0.0,
    double incentivos = 0.0,
    double feriados = 0.0,
  }) {
    double factor;
    if (frecuencia == 'Semanal') {
      factor = 5.5 / 23.83; // Factor legal RD
    } else if (frecuencia == 'Quincenal') {
      factor = 0.5;
    } else {
      factor = 1.0;
    }

    // El salario base del periodo prorrateado
    double salarioBasePeriodo = salarioMensualBase * factor;
    
    // El salario bruto total incluye los extras (Horas extras, incentivos, etc.)
    double salarioBrutoTotal = salarioBasePeriodo + horasExtras + incentivos + feriados;
    
    // Calculamos AFP y SFS sobre el salario bruto total del periodo
    double afp = calculateAFP(salarioBrutoTotal);
    double sfs = calculateSFS(salarioBrutoTotal);
    
    // Para el ISR proyectamos el mensual incluyendo los extras para la escala correcta
    double extrasMensuales = (horasExtras + incentivos + feriados) / factor;
    double baseMensualProyectada = salarioMensualBase + extrasMensuales;
    
    double afpMensual = calculateAFP(baseMensualProyectada);
    double sfsMensual = calculateSFS(baseMensualProyectada);
    double isrMensual = calculateISR(baseMensualProyectada, afpMensual, sfsMensual);
    double isr = isrMensual * factor;

    double totalRetenciones = afp + sfs + isr + otrosDescuentos;
    double salarioNeto = salarioBrutoTotal - totalRetenciones;

    return {
      'salarioBruto': salarioBrutoTotal,
      'afp': afp,
      'sfs': sfs,
      'isr': isr,
      'totalRetenciones': totalRetenciones,
      'salarioNeto': salarioNeto,
    };
  }
}
