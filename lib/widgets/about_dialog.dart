import 'package:ekatapoolcompanion/utils/common.dart' as common;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

const textLinks = [
  {"name": "Ekata IO", "url": "https://ekata.io"},
  {
    "name": "Changelog",
    "url":
        "https://gitlab.ekata.io/ekata-io-projects/ekata-pool-companion/-/blob/main/changelog.md"
  }
];

const imageLink = [
  {
    "logo": "assets/images/discord-logo.png",
    "url": "https://discord.gg/KsMA8FDV",
    "name": "discord"
  },
  {
    "logo": "assets/images/telegram-logo.png",
    "url": "https://t.me/ekata_io",
    "name": "telegram"
  }
];

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
                const Text("Ekata Pool Companion"),
                Text("Version: $version"),
                const Text("Xmrig Engine Version: 6.18.0"),
                ...textLinks
                    .map((e) => GestureDetector(
                          child: Text(
                            e["name"]!,
                            style: const TextStyle(
                                decoration: TextDecoration.underline),
                          ),
                          onTap: () async {
                            if (!await launchUrl(Uri.parse(e["url"]!),
                                mode: LaunchMode.externalApplication)) {
                              throw Exception(
                                  "could not launch ${e["name"]!.toLowerCase()} url");
                            }
                          },
                        ))
                    .toList(),
                Wrap(
                  spacing: 4,
                  alignment: WrapAlignment.center,
                  children: imageLink
                      .map((e) => GestureDetector(
                          child: Image(
                            image: AssetImage(e["logo"]!),
                            width: 24,
                            height: 24,
                          ),
                          onTap: () async {
                            if (!await launchUrl(Uri.parse(e["url"]!),
                                mode: LaunchMode.externalApplication)) {
                              throw Exception(
                                  "could not launch ${e["name"]!.toLowerCase()} url");
                            }
                          }))
                      .toList(),
                )
              ],
            ),
          ));
    },
  );
}
