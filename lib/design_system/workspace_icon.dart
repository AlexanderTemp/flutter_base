import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class WorkspaceIcon extends StatelessWidget {
  const WorkspaceIcon(this.name, {super.key, this.color, this.size = 20});

  final String name;
  final Color? color;
  final double size;

  @override
  Widget build(BuildContext context) => SvgPicture.asset(
        'assets/icons/$name.svg',
        width: size,
        height: size,
        excludeFromSemantics: true,
        colorFilter: ColorFilter.mode(
          color ?? AppFlowyTheme.of(context).iconColorScheme.secondary,
          BlendMode.srcIn,
        ),
      );
}
