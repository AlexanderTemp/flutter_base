import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:flutter/material.dart';

import '../application/settings_cubit.dart';

class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar(
      {super.key, required this.name, required this.color, this.size = 56});
  final String name;
  final int color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = AppFlowyTheme.of(context);
    final colors = [
      theme.fillColorScheme.infoLight,
      theme.fillColorScheme.successLight,
      theme.fillColorScheme.warningLight,
      theme.fillColorScheme.featuredLight
    ];
    return ExcludeSemantics(
        child: Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
          color: colors[color], borderRadius: BorderRadius.circular(size / 3)),
      child: Text(name.characters.first.toUpperCase(),
          style: theme.textStyle.heading3
              .enhanced(color: theme.textColorScheme.primary)),
    ));
  }
}

class SettingsProfileCard extends StatelessWidget {
  const SettingsProfileCard(
      {super.key,
      required this.settings,
      required this.subtitle,
      required this.onTap});
  final SettingsState settings;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = AppFlowyTheme.of(context);
    return Semantics(
        button: true,
        container: true,
        child: AFBaseButton(
          onTap: onTap,
          padding: const EdgeInsets.all(20),
          borderRadius: theme.borderRadius.l,
          borderColor: (_, __, ___, ____) => theme.borderColorScheme.primary,
          backgroundColor: (_, hover, __) => hover
              ? theme.fillColorScheme.contentHover
              : theme.surfaceColorScheme.primary,
          builder: (_, __, ___) => Row(children: [
            ProfileAvatar(
                name: settings.profileName, color: settings.avatarColor),
            const SizedBox(width: 16),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(settings.profileName,
                      style: theme.textStyle.title
                          .enhanced(color: theme.textColorScheme.primary)),
                  const SizedBox(height: 4),
                  Text(subtitle,
                      style: theme.textStyle.caption
                          .standard(color: theme.textColorScheme.secondary)),
                ])),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right, color: theme.iconColorScheme.secondary),
          ]),
        ));
  }
}

class SettingsGroup extends StatelessWidget {
  const SettingsGroup({super.key, required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = AppFlowyTheme.of(context);
    return Padding(
        padding: const EdgeInsets.only(top: 28),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 10),
              child: Text(title.toUpperCase(),
                  style: theme.textStyle.caption
                      .enhanced(color: theme.textColorScheme.secondary))),
          DecoratedBox(
              decoration: BoxDecoration(
                  color: theme.surfaceColorScheme.primary,
                  border: Border.all(color: theme.borderColorScheme.primary),
                  borderRadius: BorderRadius.circular(theme.borderRadius.l)),
              child: Column(children: [
                for (var i = 0; i < children.length; i++) ...[
                  if (i > 0)
                    Divider(
                        height: 1,
                        indent: 52,
                        color: theme.borderColorScheme.primary),
                  children[i],
                ],
              ])),
        ]));
  }
}

class SettingsTile extends StatelessWidget {
  const SettingsTile(
      {super.key,
      required this.title,
      required this.subtitle,
      required this.icon,
      required this.onTap,
      this.selected = false});
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final theme = AppFlowyTheme.of(context);
    return Semantics(
        button: true,
        container: true,
        selected: selected,
        child: AFBaseButton(
            onTap: onTap,
            padding: const EdgeInsets.all(16),
            borderRadius: theme.borderRadius.l,
            borderColor: (_, __, ___, ____) => Colors.transparent,
            backgroundColor: (_, hover, __) => selected
                ? theme.fillColorScheme.themeSelect
                : hover
                    ? theme.fillColorScheme.contentHover
                    : Colors.transparent,
            builder: (_, __, ___) => Row(children: [
                  Icon(icon,
                      size: 22,
                      color: selected
                          ? theme.textColorScheme.action
                          : theme.iconColorScheme.secondary),
                  const SizedBox(width: 14),
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text(title,
                            style: theme.textStyle.body.enhanced(
                                color: theme.textColorScheme.primary)),
                        const SizedBox(height: 4),
                        Text(subtitle,
                            style: theme.textStyle.caption.standard(
                                color: theme.textColorScheme.secondary)),
                      ])),
                  const SizedBox(width: 8),
                  Icon(Icons.chevron_right,
                      size: 18, color: theme.iconColorScheme.tertiary),
                ])));
  }
}
