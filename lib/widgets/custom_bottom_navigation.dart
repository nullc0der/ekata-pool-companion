import 'package:flutter/material.dart';

class CustomBottomNavigation extends StatelessWidget {
  const CustomBottomNavigation(
      {Key? key,
      required this.selectedIndex,
      required this.items,
      required this.onItemSelected})
      : assert(items.length >= 2 && items.length <= 5),
        super(key: key);

  final List<CustomBottomNavigationItem> items;
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: Theme.of(context).primaryColor),
      child: SafeArea(
        child: SizedBox(
            width: double.infinity,
            height: 80,
            child:
                Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: items.map((item) {
                  var index = items.indexOf(item);
                  return GestureDetector(
                    onTap: () => onItemSelected(index),
                    behavior: HitTestBehavior.opaque,
                    child: _CustomBottomNavigationIcon(
                        selectedIcon: item.selectedIcon,
                        unselectedIcon: item.unselectedIcon,
                        image: item.image,
                        title: item.title,
                        isSelected: index == selectedIndex),
                  );
                }).toList(),
              )
            ])),
      ),
    );
  }
}

class _CustomBottomNavigationIcon extends StatelessWidget {
  const _CustomBottomNavigationIcon(
      {Key? key,
      this.selectedIcon,
      this.unselectedIcon,
      this.image,
      required this.title,
      required this.isSelected})
      : assert(
            image != null || (selectedIcon != null && unselectedIcon != null)),
        super(key: key);

  final IconData? selectedIcon;
  final IconData? unselectedIcon;
  final Image? image;
  final String title;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 12),
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color:
                    isSelected ? Colors.white : Theme.of(context).primaryColor),
            child: (selectedIcon != null && unselectedIcon != null)
                ? Icon(
                    isSelected ? selectedIcon : unselectedIcon,
                    color: isSelected
                        ? Theme.of(context).primaryColor
                        : Colors.white,
                    size: 24,
                  )
                : Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12)),
                    child: image,
                  )),
        const SizedBox(
          height: 6,
        ),
        Text(title,
            style: TextStyle(
                color: Colors.white,
                fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal))
      ],
    );
  }
}

class CustomBottomNavigationItem {
  CustomBottomNavigationItem(
      {this.selectedIcon, this.unselectedIcon, this.image, required this.title})
      : assert(
            image != null || (selectedIcon != null && unselectedIcon != null));
  final IconData? selectedIcon;
  final IconData? unselectedIcon;
  final Image? image;
  final String title;
}
