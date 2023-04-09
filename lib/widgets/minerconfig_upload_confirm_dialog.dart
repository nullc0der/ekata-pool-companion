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
            TextButton(
                onPressed: () {
                  Navigator.pop(context, false);
                },
                child: const Text("No")),
            FilledButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text("Yes"),
            )
          ],
        );
      });
}
