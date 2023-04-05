import 'dart:convert';

import 'package:ekatapoolcompanion/models/minerconfig.dart';
import 'package:ekatapoolcompanion/pages/miner/miner.dart';
import 'package:ekatapoolcompanion/providers/minerstatus.dart';
import 'package:ekatapoolcompanion/providers/uistate.dart';
import 'package:ekatapoolcompanion/services/minerconfig.dart';
import 'package:ekatapoolcompanion/utils/common.dart';
import 'package:ekatapoolcompanion/utils/constants.dart';
import 'package:ekatapoolcompanion/utils/desktop_miner/miner.dart';
import 'package:ekatapoolcompanion/widgets/minerconfig_edit_confirm_dialog.dart';
import 'package:ekatapoolcompanion/widgets/minerconfig_upload_confirm_dialog.dart';
import 'package:ekatapoolcompanion/widgets/passwordtextformfield.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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
  bool _isEditingUsersMinerConfig = false;
  final _minerConfigFormKey = GlobalKey<FormState>();
  final _minerConfigFieldController = TextEditingController();
  final _xmrigCCServerUrlFieldController = TextEditingController();
  final _xmrigCCServerTokenFieldController = TextEditingController();
  final _xmrigCCWorkerIdFieldController = TextEditingController();
  final _threadCountFieldController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final minerStatusProvider =
        Provider.of<MinerStatusProvider>(context, listen: false);
    if (minerStatusProvider.usersMinerConfig?.minerConfig != null) {
      _minerConfigFieldController.text = JsonEncoder.withIndent(" " * 2)
          .convert(minerStatusProvider.usersMinerConfig?.minerConfig);
      _isEditingUsersMinerConfig = true;
    }
    if (minerStatusProvider.minerConfig != null) {
      _minerConfigFieldController.text = minerConfigToJson(
          minerStatusProvider.minerConfig!,
          prettyPrint: true);
    }
    if (minerStatusProvider.threadCount != null) {
      _threadCountFieldController.text =
          minerStatusProvider.threadCount.toString();
    }
    _loadXmrigCCOptions();
  }

  @override
  void dispose() {
    _minerConfigFieldController.dispose();
    _xmrigCCServerUrlFieldController.dispose();
    _xmrigCCServerTokenFieldController.dispose();
    _xmrigCCWorkerIdFieldController.dispose();
    _threadCountFieldController.dispose();
    super.dispose();
  }

  Future<void> _loadXmrigCCOptions() async {
    final prefs = await SharedPreferences.getInstance();
    String xmrigCCOptions =
        prefs.getString(Constants.xmrigCCOptionsSharedPrefs) ?? "";
    if (xmrigCCOptions.isNotEmpty) {
      final xmrigCCOptionsJson = jsonDecode(xmrigCCOptions);
      if (xmrigCCOptionsJson.isNotEmpty) {
        Provider.of<MinerStatusProvider>(context, listen: false)
            .xmrigCCServerUrl = xmrigCCOptionsJson["xmrigCCServerUrl"];
        Provider.of<MinerStatusProvider>(context, listen: false)
            .xmrigCCServerToken = xmrigCCOptionsJson["xmrigCCServerToken"];
        Provider.of<MinerStatusProvider>(context, listen: false)
            .xmrigCCWorkerId = xmrigCCOptionsJson["xmrigCCWorkerId"];
        _xmrigCCServerUrlFieldController.text =
            xmrigCCOptionsJson["xmrigCCServerUrl"];
        _xmrigCCServerTokenFieldController.text =
            xmrigCCOptionsJson["xmrigCCServerToken"];
        _xmrigCCWorkerIdFieldController.text =
            xmrigCCOptionsJson["xmrigCCWorkerId"] != null &&
                    xmrigCCOptionsJson["xmrigCCWorkerId"].isNotEmpty
                ? xmrigCCOptionsJson["xmrigCCWorkerId"]
                : "epc-worker-${getRandomString(6)}";
      } else {
        _xmrigCCServerUrlFieldController.text = "127.0.0.1:3344";
        _xmrigCCWorkerIdFieldController.text =
            "epc-worker-${getRandomString(6)}";
      }
    } else {
      _xmrigCCServerUrlFieldController.text = "127.0.0.1:3344";
      _xmrigCCWorkerIdFieldController.text = "epc-worker-${getRandomString(6)}";
    }
  }

  Future<void> _saveXmrigCCOptions() async {
    final prefs = await SharedPreferences.getInstance();
    Provider.of<MinerStatusProvider>(context, listen: false).xmrigCCServerUrl =
        _xmrigCCServerUrlFieldController.text;
    Provider.of<MinerStatusProvider>(context, listen: false)
        .xmrigCCServerToken = _xmrigCCServerTokenFieldController.text;
    Provider.of<MinerStatusProvider>(context, listen: false).xmrigCCWorkerId =
        _xmrigCCWorkerIdFieldController.text;
    prefs.setString(
        Constants.xmrigCCOptionsSharedPrefs,
        jsonEncode({
          "xmrigCCServerUrl": _xmrigCCServerUrlFieldController.text,
          "xmrigCCServerToken": _xmrigCCServerTokenFieldController.text,
          "xmrigCCWorkerId": _xmrigCCWorkerIdFieldController.text
        }));
  }

  Future<void> _saveMinerConfigInBackend(String config, bool userUploaded,
      {bool update = false, String currentMinerConfigMd5 = ""}) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString(Constants.userIdSharedPrefs);
    final poolCredentials = {};
    if (userId != null) {
      final minerConfig = jsonDecode(config);
      if (minerConfig["pools"].isNotEmpty) {
        if (userUploaded) {
          minerConfig["pools"].forEach((pool) {
            poolCredentials[pool["url"]] = {
              "user": pool["user"],
              "pass": pool["pass"]
            };
          });
        }
        final newPools = minerConfig["pools"].map((pool) {
          pool["user"] = null;
          pool["pass"] = null;
          return pool;
        }).toList();
        minerConfig["pools"] = newPools;
      }
      try {
        if (userUploaded) {
          String? minerConfigMd5;
          if (!update) {
            minerConfigMd5 = await MinerConfigService.createMinerConfig(
              userId: userId,
              minerConfig: jsonEncode(minerConfig).trim(),
              userUploaded: true,
            );
          } else {
            minerConfigMd5 = await MinerConfigService.updateMinerConfig(
                userId: userId,
                minerConfig: jsonEncode(minerConfig).trim(),
                minerConfigMd5: currentMinerConfigMd5);
          }
          if (minerConfigMd5 != null && poolCredentials.isNotEmpty) {
            // NOTE: This and WalletAddress widget saves pool credentials
            // to different key, need to merge this to WalletAddress preference
            // also need to add a merger function on init so that existing
            // preferences gets merged seamlessly
            final poolCredentialsPrefs =
                prefs.getString(Constants.poolCredentialsSharedPrefs);
            if (poolCredentialsPrefs != null) {
              final Map<String, dynamic> poolCredentialPrefsDecoded =
                  jsonDecode(poolCredentialsPrefs);
              if (poolCredentialPrefsDecoded
                  .containsKey(currentMinerConfigMd5)) {
                poolCredentialPrefsDecoded.remove(currentMinerConfigMd5);
              }
              prefs.setString(
                  Constants.poolCredentialsSharedPrefs,
                  jsonEncode({
                    ...poolCredentialPrefsDecoded,
                    minerConfigMd5: poolCredentials
                  }));
            } else {
              prefs.setString(Constants.poolCredentialsSharedPrefs,
                  jsonEncode({minerConfigMd5: poolCredentials}));
            }
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: update
                    ? const Text("MinerConfig update successfully")
                    : const Text("MinerConfig saved successfully")));
          }
        } else {
          await MinerConfigService.createMinerConfig(
              userId: userId, minerConfig: jsonEncode(minerConfig).trim());
        }
      } on Exception catch (_) {}
    }
  }

  Future<void> _onPressStartMining() async {
    if (_minerConfigFormKey.currentState!.validate()) {
      _minerConfigFormKey.currentState!.save();
      _saveXmrigCCOptions();
      final String value = _minerConfigFieldController.text;
      if (value.isNotEmpty) {
        bool? userConfirmedUpload;
        EditConfirm? userConfirmedUpdate;
        setState(() {
          _isMinerConfigSaving = true;
        });
        if (!_isEditingUsersMinerConfig) {
          userConfirmedUpload =
              await showMinerConfigUploadConfirmDialog(context);
          if (!kDebugMode) {
            await _saveMinerConfigInBackend(
                value, userConfirmedUpload ?? false);
          }
        } else {
          final usersMinerConfigUnEdited =
              Provider.of<MinerStatusProvider>(context, listen: false)
                  .usersMinerConfig;
          if (usersMinerConfigUnEdited != null) {
            if (JsonEncoder.withIndent(" " * 2)
                    .convert(usersMinerConfigUnEdited.minerConfig)
                    .trim() !=
                value.trim()) {
              userConfirmedUpdate =
                  await showMinerConfigEditConfirmDialog(context);
            }
            if (!kDebugMode) {
              switch (userConfirmedUpdate) {
                case EditConfirm.update:
                  await _saveMinerConfigInBackend(value, true,
                      update: true,
                      currentMinerConfigMd5:
                          usersMinerConfigUnEdited.minerConfigMd5);
                  break;
                case EditConfirm.dontSave:
                  await _saveMinerConfigInBackend(value, false);
                  break;
                case EditConfirm.saveAsNew:
                  await _saveMinerConfigInBackend(value, true);
                  break;
                default:
                  await _saveMinerConfigInBackend(value, false);
                  break;
              }
            }
          }
        }
        final filePath = await saveMinerConfigToFile(value);
        final minerConfig = minerConfigFromJson(value);
        Provider.of<MinerStatusProvider>(context, listen: false).minerConfig =
            minerConfig;
        Provider.of<MinerStatusProvider>(context, listen: false)
            .minerConfigPath = filePath;
        // Provider.of<UiStateProvider>(context, listen: false).showBottomNavbar =
        //     minerConfig.pools.first.url == "70.35.206.105:3333" ||
        //         minerConfig.pools.first.url == "70.35.206.105:5555";
        // Provider.of<UiStateProvider>(context, listen: false)
        //     .bottomNavigationIndex = 3;
        widget.setCurrentWizardStep(WizardStep.miner);
      }
    }
  }

  Widget _getMinerBackendDropdown(MinerBinary selectedMinerBinary) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<MinerBinary>(
            isExpanded: true,
            decoration: const InputDecoration(labelText: "Miner Backend"),
            value: selectedMinerBinary,
            items: MinerBinary.values
                .map<DropdownMenuItem<MinerBinary>>(
                    (MinerBinary minerBinary) => DropdownMenuItem<MinerBinary>(
                          child: Text(minerBinary.name),
                          value: minerBinary,
                        ))
                .toList(),
            onChanged: (MinerBinary? minerBinary) {
              if (minerBinary != null) {
                Provider.of<MinerStatusProvider>(context, listen: false)
                    .selectedMinerBinary = minerBinary;
              }
            })
      ],
    );
  }

  Widget _getXmrigCCOptions() {
    return Column(
      children: [
        TextFormField(
          controller: _xmrigCCServerUrlFieldController,
          decoration: const InputDecoration(labelText: "xmrigCC Server url"),
          autovalidateMode: AutovalidateMode.onUserInteraction,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return "URL can't be empty";
            }
            return null;
          },
          onSaved: (value) {
            _xmrigCCServerUrlFieldController.text = value ?? "";
          },
        ),
        const SizedBox(
          height: 8.0,
        ),
        PasswordTextFormField(
          controller: _xmrigCCServerTokenFieldController,
          labelText: "xmrigCC Server token",
          autovalidateMode: AutovalidateMode.onUserInteraction,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return "Token can't be empty";
            }
            return null;
          },
          onSaved: (value) {
            _xmrigCCServerTokenFieldController.text = value ?? "";
          },
        ),
        const SizedBox(
          height: 8.0,
        ),
        TextFormField(
          controller: _xmrigCCWorkerIdFieldController,
          decoration:
              const InputDecoration(labelText: "xmrigCC Worker ID (Optional)"),
          onSaved: (value) {
            if (value != null && value.isNotEmpty) {
              _xmrigCCWorkerIdFieldController.text = value ?? "";
            }
          },
        ),
      ],
    );
  }

  Widget _getThreadCountInput() {
    return TextFormField(
      controller: _threadCountFieldController,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      validator: (value) {
        if (value != null && value.isNotEmpty) {
          if (int.tryParse(value) == null) {
            return "Make sure to enter numeric value";
          }
          if (int.tryParse(value)! <= 0) {
            return "Make sure to enter a value greater than 0";
          }
        }
        return null;
      },
      keyboardType: TextInputType.number,
      decoration: const InputDecoration(
        labelText: "Enter Thread Count(Optional)",
      ),
      onSaved: (value) {
        if (value != null &&
            int.tryParse(value) != null &&
            int.tryParse(value)! > 0) {
          Provider.of<MinerStatusProvider>(context, listen: false).threadCount =
              int.tryParse(value);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedMinerBinary =
        Provider.of<MinerStatusProvider>(context).selectedMinerBinary;
    final minerConfigPageShowMinerEngineSelect =
        Provider.of<UiStateProvider>(context)
            .minerConfigPageShowMinerEngineSelect;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Form(
          key: _minerConfigFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Review Config",
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              Expanded(
                  child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    children: [
                      TextFormField(
                          minLines: 1,
                          maxLines: 12,
                          controller: _minerConfigFieldController,
                          decoration: const InputDecoration(
                              labelText: "Edit your miner config here:",
                              alignLabelWithHint: true),
                          autovalidateMode: AutovalidateMode.onUserInteraction,
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
                      if (minerConfigPageShowMinerEngineSelect) ...[
                        _getMinerBackendDropdown(selectedMinerBinary),
                        const SizedBox(
                          height: 8.0,
                        ),
                        if (selectedMinerBinary == MinerBinary.xmrigCC) ...[
                          _getXmrigCCOptions(),
                          const SizedBox(
                            height: 8.0,
                          )
                        ],
                        _getThreadCountInput(),
                        const SizedBox(
                          height: 8.0,
                        ),
                      ],
                    ],
                  ),
                ),
              )),
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
                          style: ElevatedButton.styleFrom(
                              shadowColor: Colors.transparent),
                          onPressed: _onPressStartMining,
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
          )),
    );
  }
}
