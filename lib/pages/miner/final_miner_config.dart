import 'dart:convert';
import 'dart:io';

import 'package:ekatapoolcompanion/models/minerconfig.dart';
import 'package:ekatapoolcompanion/pages/miner/miner.dart';
import 'package:ekatapoolcompanion/providers/minerstatus.dart';
import 'package:ekatapoolcompanion/providers/uistate.dart';
import 'package:ekatapoolcompanion/services/minerconfig.dart';
import 'package:ekatapoolcompanion/utils/constants.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FinalMinerConfig extends StatefulWidget {
  const FinalMinerConfig({Key? key, required this.setCurrentWizardStep})
      : super(key: key);

  final ValueChanged<WizardStep> setCurrentWizardStep;

  @override
  State<FinalMinerConfig> createState() => _FinalMinerConfigState();
}

class _FinalMinerConfigState extends State<FinalMinerConfig> {
  bool _isMinerConfigSaving = false;
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

  Future<void> _saveMinerConfigInBackend(String config) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString(Constants.userIdSharedPrefs);
    if (userId != null) {
      final minerConfig = jsonDecode(config);
      if (minerConfig["pools"].isNotEmpty) {
        final newPools = minerConfig["pools"].map((pool) {
          pool["user"] = null;
          pool["pass"] = null;
          return pool;
        }).toList();
        minerConfig["pools"] = newPools;
      }
      try {
        await MinerConfigService.createMinerConfig(
            userId: userId, minerConfig: jsonEncode(minerConfig).trim());
      } on Exception catch (_) {}
    }
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
                                setState(() {
                                  _isMinerConfigSaving = true;
                                });
                                final filePath =
                                    await _saveMinerConfigToFile(value);
                                if (!kDebugMode) {
                                  await _saveMinerConfigInBackend(value);
                                }
                                final minerConfig = minerConfigFromJson(value);
                                Provider.of<MinerStatusProvider>(context,
                                        listen: false)
                                    .minerConfig = minerConfig;
                                Provider.of<MinerStatusProvider>(context,
                                        listen: false)
                                    .minerConfigPath = filePath;
                                Provider.of<UiStateProvider>(context,
                                            listen: false)
                                        .showBottomNavbar =
                                    minerConfig.pools.first.url ==
                                            "70.35.206.105:3333" ||
                                        minerConfig.pools.first.url ==
                                            "70.35.206.105:5555";
                                Provider.of<UiStateProvider>(context,
                                        listen: false)
                                    .bottomNavigationIndex = 3;
                                widget.setCurrentWizardStep(WizardStep.miner);
                              }
                            }
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text("Start Mining"),
                              if (_isMinerConfigSaving) ...[
                                const SizedBox(
                                  width: 4,
                                ),
                                const SizedBox(
                                  width: 10,
                                  height: 10,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                  ),
                                )
                              ]
                            ],
                          )),
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
