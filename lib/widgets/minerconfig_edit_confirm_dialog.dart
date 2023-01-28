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
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 2,
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context, EditConfirm.dontSave);
                  },
                  child: const Text("Don't save"),
                ),
                ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context, EditConfirm.update);
                    },
                    child: const Text("Update"),
                    style: ButtonStyle(
                      backgroundColor:
                          MaterialStateProperty.all(Colors.blue.shade900),
                    )),
                ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context, EditConfirm.saveAsNew);
                    },
                    child: const Text("Save as new"),
                    style: ButtonStyle(
                        backgroundColor:
                            MaterialStateProperty.all(Colors.green.shade900)))
              ],
            )
          ],
        );
      });
}
