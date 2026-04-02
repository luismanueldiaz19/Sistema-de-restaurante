import 'package:flutter/material.dart';

class LwaderSoftTheme extends ThemeExtension<LwaderSoftTheme> {
  final Color dataTableHeader;
  final Color dataTableRow;
  final Color cardBackground;
  final Color snackbarBackground;
  final Color snackbarText;

  const LwaderSoftTheme({
    required this.dataTableHeader,
    required this.dataTableRow,
    required this.cardBackground,
    required this.snackbarBackground,
    required this.snackbarText,
  });

  @override
  LwaderSoftTheme copyWith({
    Color? dataTableHeader,
    Color? dataTableRow,
    Color? cardBackground,
    Color? snackbarBackground,
    Color? snackbarText,
  }) {
    return LwaderSoftTheme(
      dataTableHeader: dataTableHeader ?? this.dataTableHeader,
      dataTableRow: dataTableRow ?? this.dataTableRow,
      cardBackground: cardBackground ?? this.cardBackground,
      snackbarBackground: snackbarBackground ?? this.snackbarBackground,
      snackbarText: snackbarText ?? this.snackbarText,
    );
  }

  @override
  LwaderSoftTheme lerp(ThemeExtension<LwaderSoftTheme>? other, double t) {
    if (other is! LwaderSoftTheme) return this;
    return LwaderSoftTheme(
      dataTableHeader: Color.lerp(dataTableHeader, other.dataTableHeader, t)!,
      dataTableRow: Color.lerp(dataTableRow, other.dataTableRow, t)!,
      cardBackground: Color.lerp(cardBackground, other.cardBackground, t)!,
      snackbarBackground: Color.lerp(
        snackbarBackground,
        other.snackbarBackground,
        t,
      )!,
      snackbarText: Color.lerp(snackbarText, other.snackbarText, t)!,
    );
  }
}
