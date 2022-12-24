import 'package:ekatapoolcompanion/utils/common.dart' as common;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

Future<void> showAboutAppDialog(BuildContext context) async {
  String version = await common.getPackageVersion();
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (BuildContext context) {
      return AlertDialog(
          title: const Center(
            child: Text("About"),
          ),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                GestureDetector(
                  child: const Text(
                    "Ekata IO",
                    style: TextStyle(decoration: TextDecoration.underline),
                  ),
                  onTap: () async {
                    if (!await launchUrl(Uri.parse("https://ekata.io"),
                        mode: LaunchMode.externalApplication)) {
                      throw "could not launch ekata.io url";
                    }
                  },
                ),
                const Text("Pool Companion"),
                Text("Version: $version"),
                const Text("Xmrig Engine Version: 6.18.0"),
                GestureDetector(
                  child: const Text(
                    "Changelog",
                    style: TextStyle(decoration: TextDecoration.underline),
                  ),
                  onTap: () async {
                    if (!await launchUrl(
                        Uri.parse(
                            "https://gitlab.ekata.io/ekata-io-projects/ekata-pool-companion/-/blob/main/changelog.md"),
                        mode: LaunchMode.externalApplication)) {
                      throw "could not launch changelog url";
                    }
                  },
                )
              ],
            ),
          ));
    },
  );
}
