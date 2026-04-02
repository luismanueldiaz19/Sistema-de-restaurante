import 'package:flutter/material.dart';

class NotScreenWidget extends StatelessWidget {
  const NotScreenWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme;
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Image.asset('assets/tamano-de-la-pantalla.png', scale: 4),
        Text('Pantalla no disponible', style: style.titleSmall),
        Text('para ver la información expandir la pantalla',
            style: style.bodySmall)
      ]),
    );
  }
}
