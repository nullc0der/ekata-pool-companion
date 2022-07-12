import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

Future<String> _getPackageInfo() async {
  PackageInfo packageInfo = await PackageInfo.fromPlatform();
  return packageInfo.version;
}

Future<void> showAboutAppDialog(BuildContext context) async {
  String version = await _getPackageInfo();
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (BuildContext context) {
      return AlertDialog(
          title: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.info),
            Container(
                margin: const EdgeInsets.only(left: 5.0),
                child: const Text('About'))
          ]),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                const Text('Ekata Pool Companion'),
                Text('Version: $version'),
              ],
            ),
          ));
    },
  );
}
