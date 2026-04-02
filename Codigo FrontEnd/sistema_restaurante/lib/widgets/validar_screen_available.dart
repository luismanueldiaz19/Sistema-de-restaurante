import 'package:flutter/material.dart';

import 'widget_not_screen.dart';

class ValidarScreenAvailable extends StatelessWidget {
  const ValidarScreenAvailable(
      {super.key,
      required this.windows,
      this.mobile = const NotScreenWidget()});
  final Widget windows;
  final Widget? mobile;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    // print(size);
    if (size.height > 550) {
      return size.width < 800 ? mobile! : windows;
    } else {
      return const NotScreenWidget();
    }
  }
}
