import 'package:flutter/material.dart';
import 'package:ouro_pay_consumer_app/theme/app_theme.dart';

class OuroPayLogo extends StatelessWidget {
  final double size;
  final bool showText;
  final Color? color;

  const OuroPayLogo({
    super.key,
    this.size = 80,
    this.showText = true,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Logo container with concentric circles design
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: color != null ? null : AppColors.goldGradient,
            color: color,
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer ring
              Container(
                width: size * 0.9,
                height: size * 0.9,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: color != null
                        ? (color == AppColors.primaryGold
                            ? AppColors.darkBackground
                            : AppColors.primaryGold)
                        : AppColors.darkBackground,
                    width: size * 0.05,
                  ),
                ),
              ),
              // Inner ring
              Container(
                width: size * 0.6,
                height: size * 0.6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: color != null
                        ? (color == AppColors.primaryGold
                            ? AppColors.darkBackground
                            : AppColors.primaryGold)
                        : AppColors.darkBackground,
                    width: size * 0.03,
                  ),
                ),
              ),
              // Center circle
              Container(
                width: size * 0.3,
                height: size * 0.3,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color != null
                      ? (color == AppColors.primaryGold
                          ? AppColors.darkBackground
                          : AppColors.primaryGold)
                      : AppColors.darkBackground,
                ),
              ),
            ],
          ),
        ),

        if (showText) ...[
          SizedBox(height: size * 0.2),
          ShaderMask(
            shaderCallback: (bounds) => color != null
                ? LinearGradient(colors: [color!, color!]).createShader(bounds)
                : AppColors.goldGradient.createShader(bounds),
            child: Text(
              'OUROPAY',
              style: TextStyle(
                fontSize: size * 0.25,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 2,
              ),
            ),
          ),
          SizedBox(height: size * 0.05),
          Text(
            'DIGITAL GOLD, REAL VALUE.',
            style: TextStyle(
              fontSize: size * 0.1,
              color: AppColors.greyText,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ],
    );
  }
}

// Alternative logo for app bars and small spaces
class OuroPayIcon extends StatelessWidget {
  final double size;
  final Color? color;

  const OuroPayIcon({
    super.key,
    this.size = 32,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: color != null ? null : AppColors.goldGradient,
        color: color,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer ring
          Container(
            width: size * 0.9,
            height: size * 0.9,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: color != null
                    ? (color == AppColors.primaryGold
                        ? AppColors.darkBackground
                        : AppColors.primaryGold)
                    : AppColors.darkBackground,
                width: size * 0.05,
              ),
            ),
          ),
          // Inner circle
          Container(
            width: size * 0.4,
            height: size * 0.4,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color != null
                  ? (color == AppColors.primaryGold
                      ? AppColors.darkBackground
                      : AppColors.primaryGold)
                  : AppColors.darkBackground,
            ),
          ),
        ],
      ),
    );
  }
}
