import 'package:ekatapoolcompanion/widgets/about_dialog.dart';
import 'package:flutter/material.dart';

class CustomAppBar extends StatefulWidget implements PreferredSizeWidget {
  const CustomAppBar({Key? key, required this.title})
      : preferredSize = const Size.fromHeight(40.0),
        super(key: key);

  @override
  final Size preferredSize;

  final String title;

  @override
  State<CustomAppBar> createState() => _CustomAppBarState();
}

class _CustomAppBarState extends State<CustomAppBar> {
  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(widget.title),
      // titleSpacing: 8,
      // backgroundColor: Colors.white,
      // foregroundColor: Theme.of(context).primaryColor,
      // TODO: Check if this required in Android after FlexColorScheme
      // systemOverlayStyle: const SystemUiOverlayStyle(
      //     statusBarColor: Colors.white,
      //     statusBarIconBrightness: Brightness.dark),
      // elevation: 0,
      actions: [
        PopupMenuButton(
            offset: const Offset(0.0, 40.0),
            itemBuilder: (context) {
              return [
                PopupMenuItem(
                  onTap: () {
                    Future.delayed(const Duration(seconds: 0),
                        () => showAboutAppDialog(context));
                  },
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: const [Icon(Icons.info), Text('About')]),
                )
              ];
            })
      ],
    );
  }
}
