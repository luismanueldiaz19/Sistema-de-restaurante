import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import '../palletes/app_colors.dart';

Future waitingTime(Function ready) async {
  await Future.delayed(const Duration(seconds: 2));
  ready();
}

class CustomLoading extends StatelessWidget {
  const CustomLoading({
    super.key,
    this.image,
    this.text,
    this.isDivide = false,
    this.scale = 8,
    this.radius,
    this.size = 100,
  });
  final String? image;
  final String? text;
  final bool? isDivide;
  final double? scale;
  final double? radius;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              // 1. Progress Indicator
              SizedBox(
                width: size,
                height: size,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppColors.primary,
                  ),
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                ),
              ),
              // 2. Centered Image
              BounceInDown(
                curve: Curves.elasticInOut,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(radius ?? 50),
                  child: Image.asset(
                    image ?? 'assets/update.png',
                    width: size * 0.6,
                    height: size * 0.6,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (isDivide!) ...[
            Divider(
              indent: 100,
              endIndent: 100,
              color: AppColors.primary.withValues(alpha: 0.2),
            ),
            const SizedBox(height: 10),
          ],
          SlideInRight(
            curve: Curves.elasticInOut,
            child: Text(
              text ?? 'Cargando...',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w500,
                letterSpacing: 1.1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
