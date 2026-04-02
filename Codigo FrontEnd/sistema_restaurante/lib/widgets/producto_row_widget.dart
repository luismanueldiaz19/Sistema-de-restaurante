import 'package:flutter/material.dart';

Widget productRow(BuildContext context, String name, String price) {
  final textTheme = Theme.of(context).textTheme;
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(name, style: textTheme.bodyMedium),
        Text(
          price,
          style: textTheme.bodyMedium!.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    ),
  );
}
