import 'package:ekatapoolcompanion/providers/uistate.dart';
import 'package:ekatapoolcompanion/screens/homepage.dart';
import 'package:ekatapoolcompanion/widgets/theme_popup_menu.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ThemeChooser extends StatelessWidget {
  const ThemeChooser({Key? key, required this.setCurrentPage})
      : super(key: key);

  final ValueChanged<CurrentPage> setCurrentPage;

  @override
  Widget build(BuildContext context) {
    final UiStateProvider uiStateProvider =
        Provider.of<UiStateProvider>(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Configure Theme",
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(
            height: 16,
          ),
          FlexThemeModeSwitch(
              themeMode: uiStateProvider.themeMode,
              onThemeModeChanged: (ThemeMode mode) async {
                await uiStateProvider.setThemeMode(mode);
              },
              flexSchemeData:
                  FlexColor.schemesList[uiStateProvider.colorSchemeIndex]),
          const SizedBox(
            height: 16,
          ),
          ThemePopupMenu(
              contentPadding: EdgeInsets.zero,
              schemeIndex: uiStateProvider.colorSchemeIndex,
              onChanged: (int index) async {
                await uiStateProvider.setColorSchemeIndex(index);
              }),
          const SizedBox(
            height: 16,
          ),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                setCurrentPage(CurrentPage.other);
              },
              child: const Text("Done"),
              style: FilledButton.styleFrom(shadowColor: Colors.transparent),
            ),
          )
        ],
      ),
    );
  }
}
