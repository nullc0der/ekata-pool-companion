import 'package:flutter/material.dart';

class Tabs extends StatelessWidget {
  const Tabs(
      {Key? key,
      required this.tabItems,
      required this.selectedIndex,
      required this.onItemSelected})
      : super(key: key);

  final List<TabItem> tabItems;
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).primaryColor),
          borderRadius: BorderRadius.circular(6)),
      child: Row(
        children: tabItems.map((e) {
          int index = tabItems.indexOf(e);
          return Expanded(
              child: GestureDetector(
                  onTap: () => onItemSelected(index),
                  behavior: HitTestBehavior.opaque,
                  child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: index == selectedIndex
                            ? Theme.of(context).primaryColor
                            : Colors.transparent,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              e.iconData,
                              color: index != selectedIndex
                                  ? Theme.of(context).primaryColor
                                  : Colors.white,
                            ),
                            const SizedBox(
                              width: 8,
                            ),
                            Text(
                              e.tabName,
                              style: TextStyle(
                                  color: index != selectedIndex
                                      ? Theme.of(context).primaryColor
                                      : Colors.white),
                            )
                          ],
                        ),
                      ))));
        }).toList(),
      ),
    );
  }
}

class TabItem {
  const TabItem({required this.tabName, required this.iconData});

  final String tabName;
  final IconData iconData;
}
