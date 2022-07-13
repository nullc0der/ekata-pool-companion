import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

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
          title:const Center(child: Text("About"),),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                GestureDetector(
                  child: const Text("Ekata IO", style: TextStyle(decoration: TextDecoration.underline),),
                  onTap: () async {
                   if(!await launchUrl(Uri.parse('https://ekata.io'), mode: LaunchMode.externalApplication)) {
                     throw 'could not launch ekata.io';
                   }
                  },
                ),
                const Text('Pool Companion'),
                Text('Version: $version'),
              ],
            ),
          ));
    },
  );
}
