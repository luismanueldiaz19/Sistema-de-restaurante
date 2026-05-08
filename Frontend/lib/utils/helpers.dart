import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';

import '../palletes/app_colors.dart';
import 'constants.dart';

enum Operacion { sumar, restar, multiplicar, dividir }

String calcularOperacion(
  String? valor1Str,
  String? valor2Str,
  Operacion operacion,
) {
  final valor1 = double.tryParse(valor1Str ?? '');
  final valor2 = double.tryParse(valor2Str ?? '');

  if (valor1 == null || valor2 == null) {
    return '0';
  }

  double resultado;

  switch (operacion) {
    case Operacion.sumar:
      resultado = valor1 + valor2;
      break;
    case Operacion.restar:
      resultado = valor1 - valor2;
      break;
    case Operacion.multiplicar:
      resultado = valor1 * valor2;
      break;
    case Operacion.dividir:
      if (valor2 == 0) return '0'; // o 'División por cero'
      resultado = valor1 / valor2;
      break;
  }

  return resultado.toStringAsFixed(2);
}

String formatDate(DateTime date) {
  final DateFormat formatter = DateFormat('yyyy-MM-dd');
  return formatter.format(date);
}

String getDayWritted(String? fecha) {
  Intl.defaultLocale = 'es'; // Configura el idioma por defecto
  initializeDateFormatting(
    Intl.defaultLocale!,
  ); // Inicializa los datos de localización
  late DateFormat? format = DateFormat.EEEE();
  var dateString = format.format(
    DateTime.parse(fecha ?? DateTime.now().toString().substring(0, 10)),
  );
  return dateString.toUpperCase();
}

bool isValidEmail(String email) {
  final RegExp regex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
  return regex.hasMatch(email);
}

Future<void> showCustomDialog(
  BuildContext context,
  String title,
  String message,
) async {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: ListBody(children: <Widget>[Text(message)]),
        ),
        actions: <Widget>[
          TextButton(
            child: const Text('OK'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}

String formatCurrency(double amount) {
  return NumberFormat.currency(locale: 'en_US', symbol: 'RD\$ ').format(amount);
}

String formatMoneda(double amount) {
  return NumberFormat.simpleCurrency(
    locale: 'en_US',
    name: 'RD\$ ',
  ).format(amount);
}

String formatFechaLatina(DateTime date) {
  return DateFormat('dd/MM/yyyy').format(date);
}

String formatFechaHora(DateTime date) {
  return DateFormat('dd/MM/yyyy hh:mm a').format(date);
}

// String generateUUID() {
//   ///generador de UUID
//   const uuid = Uuid();
//   var idUID = uuid.v4();
//   return idUID;
// }

Widget buildTextField(
  String label, {
  String? hintText,
  TextEditingController? controller,
  List<TextInputFormatter>? inputFormatters,
  TextInputType keyboardType = TextInputType.text,
  bool obscureText = false,
  bool enabled = true,
  bool readOnly = false,
  Function()? onEditingComplete,
  Function(String)? onChanged,
  double width = 250,
  FocusNode? focusNode,
  BuildContext? context,
}) {
  return Container(
    color: Colors.white,
    width: width,
    height: 50,
    margin: const EdgeInsets.symmetric(vertical: 5),
    child: TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      enabled: enabled,
      readOnly: readOnly,
      focusNode: focusNode,
      inputFormatters: inputFormatters,
      onEditingComplete: onEditingComplete,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hintText,
        labelText: label,
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(horizontal: 15.0),
        labelStyle: TextStyle(
          color: context != null
              ? Theme.of(context).colorScheme.secondary
              : Colors.grey,
        ),
      ),
    ),
  );
}

Widget buildTextFieldValidator({
  String? hintText,
  required String label,
  TextEditingController? controller,
  List<TextInputFormatter>? inputFormatters,
  TextInputType keyboardType = TextInputType.text,
  Function? onChanged,
  Function? onFieldSubmitted,
  Function? onEditingComplete,
  bool readOnly = false,
  double? width = 250,
  FocusNode? focusNode,
  bool enabled = true,
  IconData? helpIcon,
  String? helpMessage,
}) {
  return Container(
    color: Colors.white,
    height: 50,
    width: width,
    margin: const EdgeInsets.symmetric(vertical: 5),
    child: TextFormField(
      focusNode: focusNode,
      readOnly: readOnly,
      onChanged: onChanged == null ? null : (val) => onChanged(val),
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      enabled: enabled,
      onEditingComplete: onEditingComplete == null
          ? null
          : () => onEditingComplete(),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Por favor, ingrese $label';
        }
        return null;
      },
      decoration: InputDecoration(
        hintText: hintText,
        labelText: label,
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(horizontal: 15.0),
        suffixIcon: helpIcon != null
            ? Tooltip(
                message: helpMessage ?? '',
                child: Icon(helpIcon, size: 20),
              )
            : null,
      ),
      onFieldSubmitted: onFieldSubmitted == null
          ? null
          : (val) => onFieldSubmitted(val),
    ),
  );
}

Widget buildTextFieldValidatorExpanded({
  String? hintText,
  required String label,
  TextEditingController? controller,
  List<TextInputFormatter>? inputFormatters,
  TextInputType keyboardType = TextInputType.text,
  Function? onChanged,
  Function? onFieldSubmitted,
  Function? onEditingComplete,
  bool readOnly = false,
  double? width = 250,
  FocusNode? focusNode,
  bool enabled = true,
  IconData? helpIcon,
  String? helpMessage,
  bool isMultiline = false, // nuevo parámetro
}) {
  return Container(
    color: Colors.white,
    width: width,
    margin: const EdgeInsets.symmetric(vertical: 5),
    child: TextFormField(
      focusNode: focusNode,
      readOnly: readOnly,
      onChanged: onChanged == null ? null : (val) => onChanged(val),
      controller: controller,
      keyboardType: isMultiline ? TextInputType.multiline : keyboardType,
      inputFormatters: inputFormatters,
      enabled: enabled,
      onEditingComplete: onEditingComplete == null
          ? null
          : () => onEditingComplete(),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Por favor, ingrese $label';
        }
        return null;
      },
      minLines: isMultiline ? 5 : 1,
      maxLines: isMultiline ? null : 1,
      decoration: InputDecoration(
        hintText: hintText,
        labelText: label,
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 15.0,
          vertical: 10.0,
        ),
        suffixIcon: helpIcon != null
            ? Tooltip(
                message: helpMessage ?? '',
                child: Icon(helpIcon, size: 20),
              )
            : null,
      ),
      onFieldSubmitted: onFieldSubmitted == null
          ? null
          : (val) => onFieldSubmitted(val),
    ),
  );
}

Widget textFieldWidgetUI({
  String? hintText,
  required String label,
  TextEditingController? controller,
  List<TextInputFormatter>? inputFormatters,
  TextInputType keyboardType = TextInputType.text,
  Function? onChanged,
  Function? onFieldSubmitted,
  Function? onEditingComplete,
  Function? onTap,
  bool readOnly = false,
  double? width = 250,
  FocusNode? focusNode,
  bool? obscureText,
  bool enabled = true,
  IconData? prefixIcon, // 👈 nuevo parámetro
  IconData? suffixIcon, // 👈 nuevo parámetro
  VoidCallback? onSuffixTap, // acción opcional para el icono derecho,
  String? Function(String?)? validator,
  bool requiredField = true,
}) {
  return Container(
    width: width,
    margin: const EdgeInsets.symmetric(vertical: 8),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(6),
      boxShadow: [
        BoxShadow(color: Colors.black12, blurRadius: 2, offset: Offset(0, 1)),
      ],
    ),
    child: TextFormField(
      controller: controller,
      obscureText: obscureText ?? false,
      focusNode: focusNode,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      readOnly: readOnly,
      enabled: enabled,
      onChanged: onChanged == null ? null : (val) => onChanged(val),
      onFieldSubmitted: onFieldSubmitted == null
          ? null
          : (val) => onFieldSubmitted(val),
      onEditingComplete: onEditingComplete == null
          ? null
          : () => onEditingComplete(),
      onTap: onTap == null ? null : () => onTap(),
      validator:
          validator ??
          (requiredField
              ? (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, ingrese $label';
                  }
                  return null;
                }
              : null),
      decoration: InputDecoration(
        hintText: hintText,
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 15,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: Color(0xFF003DA5), width: 1.5),
        ),
        prefixIcon: prefixIcon != null
            ? Icon(prefixIcon, color: Colors.blueGrey)
            : null,
        suffixIcon: suffixIcon != null
            ? InkWell(
                onTap: onSuffixTap,
                child: Icon(suffixIcon, color: Colors.blueGrey),
              )
            : null,
      ),
    ),
  );
}

Widget identy(context) =>
    Text('© 2026 $developer', style: Theme.of(context).textTheme.bodySmall);

Future<DateTime?> showCustomDatePicker(BuildContext context) async {
  DateTime? selectedDate = await showDatePicker(
    context: context,
    initialDate: DateTime.now(),
    firstDate: DateTime(2000),
    lastDate: DateTime(2150),
  );

  if (selectedDate != null) {
    return selectedDate;
  }

  return null; // Si no se selecciona ninguna fecha
}

DateTime calculateNextPaymentDate(DateTime startDate, String paymentMode) {
  DateTime nextPaymentDate;

  switch (paymentMode.toLowerCase()) {
    case 'semanal':
      nextPaymentDate = startDate.add(const Duration(days: 7));
      break;
    case 'quincenal':
      nextPaymentDate = startDate.add(const Duration(days: 14));
      break;
    case 'mensual':
      nextPaymentDate = DateTime(
        startDate.year,
        startDate.month + 1,
        startDate.day,
      );
      // Ajusta el día del mes si supera el número de días en el mes siguiente
      if (nextPaymentDate.month != startDate.month + 1) {
        nextPaymentDate = DateTime(
          nextPaymentDate.year,
          nextPaymentDate.month,
          0,
        ); // Último día del mes
      }
      break;
    default:
      throw ArgumentError(
        'Modo de pago no válido. Debe ser "semanal", "quincenal" o "mensual".',
      );
  }

  return nextPaymentDate;
}

DateTime _startDate = DateTime.now();
DateTime _endDate = DateTime.now();

Future<void> selectDateRange(BuildContext context, final Function press) async {
  DateTimeRange? picked = await showDateRangePicker(
    context: context,
    firstDate: DateTime(2021),
    lastDate: DateTime(2100),
    initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
  );

  if (picked != null) {
    _startDate = picked.start;
    _endDate = picked.end;
    press(
      _startDate.toString().substring(0, 10),
      _endDate.toString().substring(0, 10),
    );
  }
}

///metodo para extraer la semana correspondientes
Map<String, String> getWeekDates(DateTime date) {
  // Obtener el lunes de la semana a la que pertenece la fecha
  DateTime monday = date.subtract(Duration(days: date.weekday - 1));

  // Obtener el domingo de la semana a la que pertenece la fecha
  DateTime sunday = monday.add(const Duration(days: 6));

  // Formatear las fechas
  String formattedMonday = DateFormat('yyyy-MM-dd').format(monday);
  String formattedSunday = DateFormat('yyyy-MM-dd').format(sunday);
  // Crear un mapa con la fecha de inicio y fin
  return {'start': formattedMonday, 'end': formattedSunday};
}

const shadow = BoxShadow(
  color: Colors.black26,
  offset: Offset(0, 4),
  blurRadius: 10,
);

///metodo para extraer el anual fecha correspondientes
Map<String, String> getDateComplete(DateTime date) {
  // Primer día del año
  DateTime firstDayOfYear = DateTime(date.year, 1, 1);

  // Último día del año
  DateTime lastDayOfYear = DateTime(date.year, 12, 31);

  // Formateador para mostrar las fechas en el formato 'yyyy-MM-dd'
  DateFormat formatter = DateFormat('yyyy-MM-dd');

  return {
    'start': formatter.format(firstDayOfYear),
    'end': formatter.format(lastDayOfYear),
  };
}

String getMonthLetter(String fecha) {
  List<String> nombresMeses = [
    'enero',
    'febrero',
    'marzo',
    'abril',
    'mayo',
    'junio',
    'julio',
    'agosto',
    'septiembre',
    'octubre',
    'noviembre',
    'diciembre',
  ];
  String nombreMes = nombresMeses[DateTime.parse(fecha).month - 1];
  return nombreMes.toUpperCase();
}

// DateRange getFirstAndLastDayOfMonth(String monthName) {
//   final Map<String, int> monthMap = {
//     'enero': 1,
//     'febrero': 2,
//     'marzo': 3,
//     'abril': 4,
//     'mayo': 5,
//     'junio': 6,
//     'julio': 7,
//     'agosto': 8,
//     'septiembre': 9,
//     'octubre': 10,
//     'noviembre': 11,
//     'diciembre': 12,
//   }; // Obtener el año actual
//   final DateTime now = DateTime.now();
//   final int year = now.year; // Obtener el índice del mes
//   final int monthIndex = monthMap[monthName.toLowerCase()] ??
//       1; // Crear las fechas de primer y último día del mes
//   final DateTime firstDay = DateTime(year, monthIndex, 1);
//   final DateTime lastDay = DateTime(year, monthIndex + 1, 0);
//   return DateRange(firstDay, lastDay);
// }

Future showConfirmationDialog(
  BuildContext context,
  String message,
  String concepto,
) async {
  DateTime? selectedDate = DateTime.now();
  Future<void> selectDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
    );

    if (pickedDate != null) {
      // Obtener la hora actual
      final TimeOfDay pickedTime =
          await showTimePicker(
            context: context,
            initialTime: TimeOfDay.fromDateTime(DateTime.now()),
          ) ??
          TimeOfDay.fromDateTime(DateTime.now());

      // Combinar la fecha seleccionada con la hora seleccionada
      final DateTime newDateTime = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );

      // Asignar la nueva fecha y hora
      selectedDate = newDateTime;
    }
  }

  return showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        title: Text(
          'Confirmación',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        content: SizedBox(
          width: 250,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [Text(message), Text('Concepto : $concepto')],
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => selectDate(context),
            child: Text('Elegir otra fecha'),
          ),
          TextButton(
            child: Text('Cancelar'),
            onPressed: () {
              Navigator.of(context).pop({
                'success': false,
                'fecha': selectedDate,
              }); // Devuelve falso si se cancela
            },
          ),
          TextButton(
            child: Text('Aceptar'),
            onPressed: () {
              Navigator.of(context).pop({
                'success': true,
                'fecha': selectedDate,
              }); // Devuelve true si se acepta
            },
          ),
        ],
      );
    },
  );
}

Future<bool?> showConfirmationDialogOnyAsk(
  BuildContext context,
  String message,
) {
  return showDialog<bool>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange), // Ícono
            SizedBox(width: 10),
            Text(
              'Confirmación',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
        content: SizedBox(
          width: 250,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [Text(message, style: TextStyle(fontSize: 16))],
          ),
        ),
        actions: <Widget>[
          TextButton(
            style: TextButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Cancelar', style: TextStyle(color: Colors.white)),
            onPressed: () {
              Navigator.of(context).pop(false); // Devuelve falso si se cancela
            },
          ),
          TextButton(
            style: TextButton.styleFrom(backgroundColor: Colors.green),
            child: Text('Aceptar', style: TextStyle(color: Colors.white)),
            onPressed: () {
              Navigator.of(context).pop(true); // Devuelve true si se acepta
            },
          ),
        ],
      );
    },
  );
}

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}

void showToast(
  BuildContext context,
  String message, {
  Color bgColor = Colors.black,
}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: bgColor,
      duration: const Duration(seconds: 2),
    ),
  );
}

String getResta(String num1, String num2) {
  var result = double.parse(num1) - double.parse(num2);
  return result.toStringAsFixed(2);
}

String truncateText(String text, int length) {
  if (text.length > length) {
    return '${text.substring(0, length)}...';
  } else {
    return text;
  }
}

Future<void> pickSingleDate(
  BuildContext context,
  Function(String) onSelected,
) async {
  DateTime now = DateTime.now();

  DateTime? picked = await showDatePicker(
    context: context,
    initialDate: now,
    firstDate: DateTime(1910),
    lastDate: DateTime(2100),
  );

  if (picked != null) {
    // Combinar la fecha elegida con la hora actual
    DateTime finalDateTime = DateTime(
      picked.year,
      picked.month,
      picked.day,
      now.hour,
      now.minute,
      now.second,
    );

    // Formato completo: yyyy-MM-dd HH:mm:ss
    String formatted = finalDateTime.toString().substring(0, 19);
    onSelected(formatted);
  }
}

String limitarTexto(String texto, int maxCaracteres) {
  if (texto.length <= maxCaracteres) return texto;
  return '${texto.substring(0, maxCaracteres)}...';
}

Widget limitaTextTool(
  BuildContext context,
  String? texto,
  int maxLength, {
  TextStyle? style,
  String? title,
  Color? color,
}) {
  final String limitado = limitarTexto(texto ?? 'N/A', maxLength);

  return TextButton(
    onPressed: () async {
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
        ),
        builder: (context) {
          return Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 50,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  title ?? "Comentario",
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                SelectableText(
                  texto ?? 'N/A',
                  style: const TextStyle(fontSize: 15),
                ),
                const SizedBox(height: 25),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text("Cerrar"),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Expanded(
          child: Text(
            limitado,
            style: style ?? TextStyle(color: color ?? AppColors.azulOscuro),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 4),
        Tooltip(
          message: "Leer más",
          child: Icon(
            Icons.info_outline,
            size: 17,
            color: color ?? AppColors.azulOscuro,
          ),
        ),
      ],
    ),
  );
}

filtrarPorCampo<T>(
  String texto,
  List<T> lista,
  String Function(T) obtenerCampo,
) {
  return lista
      .where(
        (item) =>
            obtenerCampo(item).toLowerCase().contains(texto.toLowerCase()),
      )
      .toList();
}

// Widget buildStyledDropdown({
//   required String label,
//   required String? value,
//   required List<String> items,
//   required void Function(String?) onChanged,
//   required TextTheme style,
//   required Color color,
//   required IconData icon,
//   double? height = 40,
//   double? width = 200,
// }) {
//   return Container(
//     height: height,
//     width: width,
//     padding: const EdgeInsets.symmetric(horizontal: 12),
//     decoration: BoxDecoration(
//       color: color.withOpacity(0.1),
//       borderRadius: BorderRadius.circular(12),
//       border: Border.all(color: color, width: 1),
//     ),
//     child: DropdownButton<String>(
//       focusColor: Colors.transparent, // 🔹 Quita el color de fondo en focus
//       focusNode: FocusNode(
//           skipTraversal: true,
//           canRequestFocus: false), // 🔹 Evita que se marque con rectángulo
//       value: value,
//       hint: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         spacing: 5,
//         children: [
//           Icon(icon, size: 18, color: color),
//           Text(label, style: style.bodySmall?.copyWith(color: color)),
//         ],
//       ),
//       icon: Icon(Icons.arrow_drop_down, color: color),
//       dropdownColor: Colors.white,
//       style: style.bodySmall?.copyWith(color: Colors.black),

//       items: items.map((m) {
//         return DropdownMenuItem<String>(
//           // alignment: Alignment.center,
//           value: m,

//           child: Tooltip(message: m, child: Text(m, style: style.bodySmall)),
//         );
//       }).toList(),
//       onChanged: onChanged,
//     ),
//   );
// }
//DropdownButtonFormField
Widget buildStyledDropdown({
  required String label,
  required String? value,
  required List<String> items,
  required void Function(String?) onChanged,
  required TextTheme style,
  required Color color,
  required IconData icon,
  double? height = 40,
  double? width = 200,
}) {
  return Container(
    height: height,
    width: width,
    padding: const EdgeInsets.symmetric(horizontal: 12),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(0),
      border: Border.all(color: color, width: 1),
    ),
    child: DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        isExpanded: true, // 🔹 Evita overflow y mantiene el tamaño
        borderRadius: BorderRadius.circular(12),
        focusColor: Colors.transparent,
        value: value,
        hint: Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 6),
            Text(label, style: style.bodySmall?.copyWith(color: color)),
          ],
        ),
        icon: Icon(Icons.arrow_drop_down, color: color),
        dropdownColor: Colors.white,
        style: style.bodySmall?.copyWith(color: Colors.black),

        items: items.map((text) {
          return DropdownMenuItem<String>(
            value: text,
            child: Tooltip(
              message: text,
              child: Text(
                text,
                overflow: TextOverflow.ellipsis,
                style: style.bodySmall,
              ),
            ),
          );
        }).toList(),

        onChanged: onChanged,
      ),
    ),
  );
}

Widget buildStyledDropdownFormField<T>({
  required String label,
  required T? value,
  required List<T> items,
  required void Function(T?) onChanged,
  required TextTheme style,
  required Color color,
  required IconData icon,
  String Function(T)? getItemLabel,
  String? Function(T?)? validator,
  double height = 40,
  double? borderRadius,
  int? limitT,
}) {
  return Container(
    height: height,
    padding: const EdgeInsets.symmetric(horizontal: 12),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(borderRadius ?? 12),
      border: Border.all(color: color, width: 1),
    ),
    child: DropdownButtonFormField<T>(
      isExpanded: true, // 🔥 evita overflow horizontal
      value: value,
      validator: validator,
      decoration: const InputDecoration(border: InputBorder.none),
      hint: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              limitarTexto(label, limitT ?? 25),
              overflow: TextOverflow.ellipsis,
              style: style.bodySmall?.copyWith(color: color),
            ),
          ),
        ],
      ),
      icon: Icon(Icons.arrow_drop_down, color: color),
      dropdownColor: Colors.white,
      style: style.bodySmall?.copyWith(color: Colors.black),
      items: items.map((m) {
        final labelItem = getItemLabel != null ? getItemLabel(m) : m.toString();

        return DropdownMenuItem<T>(
          value: m,
          child: Text(
            limitarTexto(labelItem, limitT ?? 25),
            overflow: TextOverflow.ellipsis,
            style: style.bodySmall,
          ),
        );
      }).toList(),
      onChanged: onChanged,
    ),
  );
}

getTotal<T>(List<T> collection, double Function(T) selector) {
  double total = collection.fold(0.0, (sum, item) => sum + selector(item));
  return total.toStringAsFixed(0);
}

String getGreeting() {
  // Obtener la hora actual
  DateTime now = DateTime.now();
  int hour = now.hour;

  // Definir los rangos horarios para los saludos
  String greeting;
  if (hour >= 5 && hour < 12) {
    greeting = '¡Buenos días!';
  } else if (hour >= 12 && hour < 18) {
    greeting = '¡Buenas tardes!';
  } else {
    greeting = '¡Buenas noches!';
  }

  return greeting;
}

class CustomLoginButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String text;
  final Color colorButton;
  final double? width;
  final double? height;
  final double? borderRadius;
  const CustomLoginButton({
    super.key,
    this.width = 200,
    this.height = 200,
    required this.onPressed,
    this.text = 'Iniciar Sección',
    this.colorButton = AppColors.azulOscuro,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height ?? 35,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorButton, // Azul oscuro como en la imagen
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius ?? 6),
          ),
          elevation: 3,
        ),
        onPressed: onPressed,
        child: Text(
          text,
          style: TextStyle(
            color: Colors.white,
            fontSize: 12,
            letterSpacing: 1.4,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class CustomTextIconButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String text;
  final IconData icon;
  final Color colorButton;
  final Color textColor;
  final double? width;
  final double? borderRadius;
  final double? fontSize;
  final MainAxisAlignment? mainAxisAlignment;

  const CustomTextIconButton({
    super.key,
    required this.onPressed,
    required this.icon,
    this.text = 'Aceptar',
    this.width = 200,
    this.colorButton = AppColors.azulOscuro,
    this.textColor = Colors.white,
    this.borderRadius,
    this.mainAxisAlignment,
    this.fontSize = 12,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: 35,
      child: TextButton(
        style: TextButton.styleFrom(
          backgroundColor: colorButton,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius ?? 6),
          ),
          elevation: 3,
        ),
        onPressed: onPressed,
        child: Row(
          mainAxisAlignment: mainAxisAlignment ?? MainAxisAlignment.center,
          children: [
            Icon(icon, size: fontSize, color: textColor),
            const SizedBox(width: 6),
            Text(
              text,
              style: TextStyle(
                color: textColor,
                fontSize: fontSize,
                letterSpacing: 1.4,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

bool validarFechas(String fechaCreacion, String fechaEntrega) {
  final DateTime creacion = DateTime.parse(
    fechaCreacion,
  ).subtract(Duration(days: 1));
  final DateTime entrega = DateTime.parse(fechaEntrega);
  return creacion.isBefore(entrega);
}

Widget buildEstadoBadge(String estado) {
  Color bgColor;
  Icon icon;

  switch (estado.toLowerCase()) {
    case 'pendiente':
      bgColor = Colors.orange;
      icon = const Icon(Icons.hourglass_empty, size: 14, color: Colors.white);
      break;
    case 'aprobada':
      bgColor = Colors.green;
      icon = const Icon(Icons.check_circle, size: 14, color: Colors.white);
      break;
    case 'rechazada':
      bgColor = Colors.red;
      icon = const Icon(Icons.cancel, size: 14, color: Colors.white);
      break;
    case 'finalizado':
      bgColor = Colors.blue;
      icon = const Icon(Icons.flag, size: 14, color: Colors.white);
      break;
    case 'planificado':
      bgColor = Colors.purple;
      icon = const Icon(Icons.calendar_month, size: 14, color: Colors.white);
      break;
    case 'en curso': // 👈 nuevo estado
      bgColor = Colors.lightGreen; // puedes elegir otro color que te guste
      icon = const Icon(Icons.play_arrow, size: 14, color: Colors.white);
      break;

    case 'en revisión':
      bgColor = Colors.amber;
      icon = const Icon(Icons.search, size: 14, color: Colors.white);
      break;
    case 'aprobado' || 'entregado':
      bgColor = Colors.green;
      icon = const Icon(Icons.check_circle, size: 14, color: Colors.white);
      break;
    case 'rechazado':
      bgColor = Colors.red;
      icon = const Icon(Icons.cancel, size: 14, color: Colors.white);
      break;
    case 'programado':
      bgColor = Colors.purple;
      icon = const Icon(Icons.calendar_today, size: 14, color: Colors.white);
      break;

    case 'cancelado':
      bgColor = Colors.grey;
      icon = const Icon(Icons.close, size: 14, color: Colors.white);
      break;
    case 'reprogramado' || 'despachado':
      bgColor = Colors.indigo;
      icon = const Icon(Icons.update, size: 14, color: Colors.white);
      break;
    case 'suspendido':
      bgColor = Colors.brown;
      icon = const Icon(Icons.pause_circle, size: 14, color: Colors.white);
      break;

    default:
      bgColor = Colors.grey;
      icon = const Icon(Icons.info, size: 14, color: Colors.white);
  }

  return Container(
    width: 150,
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: bgColor,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        icon,
        const SizedBox(width: 5),
        Text(
          estado.toUpperCase(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    ),
  );
}

Widget buildSeguroBadge(String estado) {
  Color bgColor;
  Icon icon;

  switch (estado.toUpperCase()) {
    case 'SIN SEGURO':
      bgColor = Colors.deepOrangeAccent;
      icon = const Icon(Icons.warning, size: 14, color: Colors.white);
      break;
    case 'ACTIVO':
      bgColor = Colors.blueAccent;
      icon = const Icon(Icons.verified, size: 14, color: Colors.white);
      break;
    case 'VENCIDO':
      bgColor = Colors.redAccent;
      icon = const Icon(Icons.error, size: 14, color: Colors.white);
      break;
    default:
      bgColor = Colors.blueGrey;
      icon = const Icon(Icons.info, size: 14, color: Colors.white);
  }

  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: bgColor,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        icon,
        const SizedBox(width: 5),
        Text(
          estado,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    ),
  );
}

class DecimalTextInputFormatter extends TextInputFormatter {
  final int decimalRange;

  DecimalTextInputFormatter({required this.decimalRange});

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;

    // Permitir vacío
    if (text.isEmpty) return newValue;

    // ❌ No permitir solo "0"
    if (text == "0") return oldValue;

    // Validar números con decimal
    if (!RegExp(r'^\d*\.?\d*$').hasMatch(text)) {
      return oldValue;
    }

    // Si incluye punto, limitar decimales
    if (text.contains(".")) {
      final parts = text.split(".");
      if (parts.length > 2) return oldValue;

      final decimals = parts[1];
      if (decimals.length > decimalRange) return oldValue;
    }

    return newValue;
  }
}

Widget buildTotalBox(
  String label,
  String value,
  Color color,
  BuildContext context, {
  IconData? icon,
}) {
  final style = Theme.of(context).textTheme;

  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
    decoration: BoxDecoration(
      border: Border.all(color: Colors.grey.shade300),
      borderRadius: BorderRadius.circular(6),
      color: Colors.white,
    ),
    child: Row(
      children: [
        if (icon != null) ...[
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 6),
        ],
        Text('$label : ', style: style.bodySmall),
        Text(
          value,
          style: style.bodySmall?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    ),
  );
}
