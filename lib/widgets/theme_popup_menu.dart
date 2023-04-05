import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';

class ThemePopupMenu extends StatelessWidget {
  const ThemePopupMenu({
    Key? key,
    required this.schemeIndex,
    required this.onChanged,
    this.contentPadding,
  }) : super(key: key);

  final int schemeIndex;
  final ValueChanged<int> onChanged;
  final EdgeInsetsGeometry? contentPadding;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isLight = theme.brightness == Brightness.light;
    final ColorScheme colorScheme = theme.colorScheme;

    return PopupMenuButton<int>(
      tooltip: '',
      padding: EdgeInsets.zero,
      onSelected: onChanged,
      itemBuilder: (BuildContext context) => FlexColor.schemesList
          .asMap()
          .entries
          .map((entry) => PopupMenuItem<int>(
                value: entry.key,
                child: ListTile(
                  dense: true,
                  leading: Icon(Icons.lens,
                      color: isLight
                          ? entry.value.light.primary
                          : entry.value.dark.primary,
                      size: 35),
                  title: Text(entry.value.name),
                ),
              ))
          .toList(),
      child: ListTile(
        contentPadding:
            contentPadding ?? const EdgeInsets.symmetric(horizontal: 16),
        title: Text(
          '${FlexColor.schemesList[schemeIndex].name} color scheme',
        ),
        subtitle: Text(FlexColor.schemesList[schemeIndex].description),
        trailing: Icon(
          Icons.lens,
          color: colorScheme.primary,
          size: 40,
        ),
      ),
    );
  }
}
