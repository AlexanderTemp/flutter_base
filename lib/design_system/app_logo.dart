import 'package:flutter/material.dart';

import '../app_info.dart';

/// Logo de la app; un fork solo reemplaza [AppInfo.logoAsset].
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 32});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      AppInfo.logoAsset,
      width: size,
      height: size,
      semanticLabel: AppInfo.name,
      // Evita decodificar la imagen fuente completa para tamaños pequeños.
      cacheWidth: (size * MediaQuery.devicePixelRatioOf(context)).round(),
    );
  }
}
