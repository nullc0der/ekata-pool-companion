import 'dart:io';

import 'package:ekatapoolcompanion/models/minerconfig.dart';
import 'package:ekatapoolcompanion/pages/miner/miner.dart';
import 'package:ekatapoolcompanion/providers/minerstatus.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

class FinalMinerConfig extends StatefulWidget {
  const FinalMinerConfig({Key? key, required this.setCurrentWizardStep})
      : super(key: key);

  final ValueChanged<WizardStep> setCurrentWizardStep;

  @override
  State<FinalMinerConfig> createState() => _FinalMinerConfigState();
}

class _FinalMinerConfigState extends State<FinalMinerConfig> {
  final _minerConfigFormKey = GlobalKey<FormState>();
  final _minerConfigFieldController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final minerConfig =
        Provider.of<MinerStatusProvider>(context, listen: false).minerConfig;
    if (minerConfig != null) {
      _minerConfigFieldController.text =
          minerConfigToJson(minerConfig, prettyPrint: true);
    }
  }

  Future<String> _saveMinerConfigToFile(String config) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = await File("${directory.path}/epc_xmrig_config.json")
        .writeAsString(config);
    return file.path;
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(8),
      children: [
        Text(
          "Review Config",
          style: TextStyle(fontSize: 18, color: Theme.of(context).primaryColor),
        ),
        const SizedBox(
          height: 8,
        ),
        Form(
          key: _minerConfigFormKey,
          child: Column(
            children: [
              TextFormField(
                  minLines: 25,
                  maxLines: 30,
                  controller: _minerConfigFieldController,
                  decoration: const InputDecoration(
                      border: OutlineInputBorder(), hintText: "Miner Config"),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Miner config can't be empty";
                    }
                    try {
                      minerConfigFromJson(value);
                    } on FormatException catch (e) {
                      return e.message;
                    }
                    return null;
                  }),
              const SizedBox(
                height: 8.0,
              ),
              SizedBox(
                width: double.infinity,
                child: Row(
                  children: [
                    Expanded(
                        child: OutlinedButton(
                            onPressed: () {
                              Provider.of<MinerStatusProvider>(context,
                                      listen: false)
                                  .minerConfig = null;
                              widget.setCurrentWizardStep(
                                  WizardStep.coinNameSelect);
                            },
                            child: const Text("Start Over"))),
                    const SizedBox(
                      width: 8,
                    ),
                    Expanded(
                      child: ElevatedButton(
                          style: ButtonStyle(
                              backgroundColor: MaterialStateProperty.all(
                                  Colors.green.shade900)),
                          onPressed: () async {
                            if (_minerConfigFormKey.currentState!.validate()) {
                              final String value =
                                  _minerConfigFieldController.text;
                              if (value.isNotEmpty) {
                                final filePath =
                                    await _saveMinerConfigToFile(value);
                                Provider.of<MinerStatusProvider>(context,
                                        listen: false)
                                    .minerConfig = minerConfigFromJson(value);
                                Provider.of<MinerStatusProvider>(context,
                                        listen: false)
                                    .minerConfigPath = filePath;
                                widget.setCurrentWizardStep(WizardStep.miner);
                              }
                            }
                          },
                          child: const Text("Start Mining")),
                    )
                  ],
                ),
              )
            ],
          ),
        )
      ],
    );
  }
}
