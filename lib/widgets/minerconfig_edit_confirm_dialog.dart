import 'package:flutter/material.dart';

enum EditConfirm { dontSave, saveAsNew, update }

Future<EditConfirm?> showMinerConfigEditConfirmDialog(
    BuildContext context) async {
  return showDialog<EditConfirm>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Do you want to update/save this config?"),
          content: const Text(
              "It seems the config is edited, do you want to save this as new or update the same config"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, EditConfirm.dontSave);
              },
              child: const Text("Don't save"),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context, EditConfirm.saveAsNew);
              },
              child: const Text("Save as new"),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context, EditConfirm.update);
              },
              child: const Text("Update"),
            ),
          ],
        );
      });
}
