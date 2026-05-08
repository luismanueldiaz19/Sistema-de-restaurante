import 'package:flutter/material.dart';

class ImagenDialogViewer extends StatelessWidget {
  final String imageUrl;
  final String descripcion;

  const ImagenDialogViewer({
    super.key,
    required this.imageUrl,
    required this.descripcion,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Imagen
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Image.network(
              imageUrl,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => const Padding(
                padding: EdgeInsets.all(16),
                child: Icon(Icons.broken_image, size: 80, color: Colors.grey),
              ),
            ),
          ),
          // Descripción
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              descripcion,
              style: const TextStyle(fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ),
          // Cerrar
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }
}
