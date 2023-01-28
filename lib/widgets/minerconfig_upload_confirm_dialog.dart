import 'package:flutter/material.dart';

Future<bool?> showMinerConfigUploadConfirmDialog(BuildContext context) async {
  return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Do you want to save this config?"),
          content:
              const Text("Doing so will make it available in my config page"),
          actions: [
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 2,
              children: [
                TextButton(
                    onPressed: () {
                      Navigator.pop(context, false);
                    },
                    child: const Text("No")),
                ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context, true);
                    },
                    child: const Text("Yes"),
                    style: ButtonStyle(
                        backgroundColor:
                            MaterialStateProperty.all(Colors.green.shade900)))
              ],
            )
          ],
        );
      });
}
