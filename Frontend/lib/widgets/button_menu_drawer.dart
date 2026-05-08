import 'package:flutter/material.dart';

class MyWidgetButton extends StatelessWidget {
  const MyWidgetButton({
    super.key,
    this.onPressed,
    this.textButton,
    this.icon = Icons.person,
    this.colorIcon,
    this.textColor,
    this.fontSize,
    this.iconSize,
    this.fontWeight,
    this.backgroundColor,
    this.padding,
    this.alignment,
    this.borderRadius,
    this.hoverColor,
  });

  final Function()? onPressed;
  final String? textButton;
  final IconData? icon;
  final Color? colorIcon;
  final Color? textColor;
  final double? fontSize;
  final double? iconSize;
  final FontWeight? fontWeight;
  final Color? backgroundColor;
  final EdgeInsetsGeometry? padding;
  final AlignmentGeometry? alignment;
  final double? borderRadius;
  final Color? hoverColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: alignment ?? Alignment.centerLeft,
      margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 4),
      child: TextButton.icon(
        style: ButtonStyle(
          padding: WidgetStateProperty.all(
            padding ?? const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
          backgroundColor: WidgetStateProperty.resolveWith<Color?>(
            (states) {
              if (states.contains(WidgetState.hovered)) {
                return hoverColor ?? Colors.indigo.withValues(alpha: 0.05);
              }
              if (states.contains(WidgetState.pressed)) {
                return Colors.indigo.withValues(alpha: 0.1);
              }
              return backgroundColor;
            },
          ),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadius ?? 6),
            ),
          ),
          overlayColor: WidgetStateProperty.all(Colors.transparent),
        ),
        onPressed: onPressed,
        icon: Icon(
          icon,
          size: iconSize ?? 20,
          color: colorIcon ?? Colors.black54,
        ),
        label: Text(
          textButton ?? 'N/A',
          style: TextStyle(
            color: textColor ?? Colors.black87,
            fontSize: fontSize ?? 14,
            fontWeight: fontWeight ?? FontWeight.w500,
          ),
        ),
      ),
    );
  }
}



// class MyWidgetButton extends StatelessWidget {
//   const MyWidgetButton({
//     super.key,
//     this.onPressed,
//     this.textButton,
//     this.icon = Icons.person,
//     this.colorIcon,
//     this.textColor,
//     this.fontSize,
//     this.iconSize,
//     this.fontWeight,
//     this.backgroundColor,
//     this.padding,
//     this.alignment,
//     this.borderRadius,
//     this.hoverColor,
//   });

//   final Function()? onPressed;
//   final String? textButton;
//   final IconData? icon;
//   final Color? colorIcon;
//   final Color? textColor;
//   final double? fontSize;
//   final double? iconSize;
//   final FontWeight? fontWeight;
//   final Color? backgroundColor;
//   final EdgeInsetsGeometry? padding;
//   final AlignmentGeometry? alignment;
//   final double? borderRadius;
//   final Color? hoverColor;

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       alignment: alignment ?? Alignment.centerLeft,
//       margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 4),
//       child: TextButton.icon(
//         style: ButtonStyle(
//           padding: WidgetStateProperty.all(
//             padding ?? const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
//           ),
//           backgroundColor: WidgetStateProperty.resolveWith<Color?>(
//             (states) {
//               if (states.contains(WidgetState.hovered)) {
//                 return hoverColor ?? Colors.indigo.withValues(alpha: 0.05);
//               }
//               if (states.contains(WidgetState.pressed)) {
//                 return Colors.indigo.withValues(alpha: 0.1);
//               }
//               return backgroundColor;
//             },
//           ),
//           shape: WidgetStateProperty.all(
//             RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(borderRadius ?? 6),
//             ),
//           ),
//           overlayColor: WidgetStateProperty.all(Colors.transparent),
//         ),
//         onPressed: onPressed,
//         icon: Icon(
//           icon,
//           size: iconSize ?? 20,
//           color: colorIcon ?? Colors.indigo.shade400,
//         ),
//         label: Text(
//           textButton ?? 'N/A',
//           style: TextStyle(
//             color: textColor ?? Colors.black87,
//             fontSize: fontSize ?? 14,
//             fontWeight: fontWeight ?? FontWeight.w500,
//           ),
//         ),
//       ),
//     );
//   }
// }

