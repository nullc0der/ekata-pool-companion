import 'package:ekatapoolcompanion/widgets/about_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CustomAppBar({Key? key, required this.title})
      : preferredSize = const Size.fromHeight(40.0),
        super(key: key);

  @override
  final Size preferredSize;

  final String title;

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title),
      titleSpacing: 8,
      backgroundColor: Colors.white,
      foregroundColor: Theme.of(context).primaryColor,
      systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.white,
          statusBarIconBrightness: Brightness.dark),
      elevation: 0,
      actions: [
        GestureDetector(
          onTap: () {},
          child: const Padding(
              padding: EdgeInsets.only(right: 2.0), child: Icon(Icons.search)),
        ),
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
