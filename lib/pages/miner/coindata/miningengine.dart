import 'dart:convert';

import 'package:ekatapoolcompanion/pages/miner/coindata/coindatawidget.dart';
import 'package:ekatapoolcompanion/providers/coindata.dart';
import 'package:ekatapoolcompanion/utils/common.dart';
import 'package:ekatapoolcompanion/utils/constants.dart';
import 'package:ekatapoolcompanion/utils/desktop_miner/miner.dart';
import 'package:ekatapoolcompanion/widgets/passwordtextformfield.dart';
import 'package:flutter/material.dart';
import 'package:matomo_tracker/matomo_tracker.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MiningEngine extends StatefulWidget {
  const MiningEngine({Key? key, required this.setCurrentCoinDataWizardStep})
      : super(key: key);

  final ValueChanged<CoinDataWizardStep?> setCurrentCoinDataWizardStep;

  @override
  State<MiningEngine> createState() => _MiningEngineState();
}

class _MiningEngineState extends State<MiningEngine> {
  final _miningEngineFormKey = GlobalKey<FormState>();
  final _xmrigCCServerUrlFieldController =
      TextEditingController(text: "127.0.0.1:3344");
  final _xmrigCCServerTokenFieldController = TextEditingController();
  final _xmrigCCWorkerIdFieldController =
      TextEditingController(text: "epc-worker-${getRandomString(6)}");
  final _threadCountFieldController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final coinDataProvider =
        Provider.of<CoinDataProvider>(context, listen: false);
    _loadXmrigCCOptions();
    if (coinDataProvider.threadCount != null) {
      _threadCountFieldController.text =
          coinDataProvider.threadCount.toString();
    }
  }

  @override
  void dispose() {
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
        Provider.of<CoinDataProvider>(context, listen: false).xmrigCCServerUrl =
            xmrigCCOptionsJson["xmrigCCServerUrl"];
        Provider.of<CoinDataProvider>(context, listen: false)
            .xmrigCCServerToken = xmrigCCOptionsJson["xmrigCCServerToken"];
        Provider.of<CoinDataProvider>(context, listen: false).xmrigCCWorkerId =
            xmrigCCOptionsJson["xmrigCCWorkerId"];
        _xmrigCCServerUrlFieldController.text =
            xmrigCCOptionsJson["xmrigCCServerUrl"];
        _xmrigCCServerTokenFieldController.text =
            xmrigCCOptionsJson["xmrigCCServerToken"];
        if (xmrigCCOptionsJson["xmrigCCWorkerId"] != null &&
            xmrigCCOptionsJson["xmrigCCWorkerId"].isNotEmpty) {
          _xmrigCCWorkerIdFieldController.text =
              xmrigCCOptionsJson["xmrigCCWorkerId"];
        }
      }
    }
  }

  Future<void> _saveXmrigCCOptions() async {
    final prefs = await SharedPreferences.getInstance();
    Provider.of<CoinDataProvider>(context, listen: false).xmrigCCServerUrl =
        _xmrigCCServerUrlFieldController.text;
    Provider.of<CoinDataProvider>(context, listen: false).xmrigCCServerToken =
        _xmrigCCServerTokenFieldController.text;
    Provider.of<CoinDataProvider>(context, listen: false).xmrigCCWorkerId =
        _xmrigCCWorkerIdFieldController.text;
    prefs.setString(
        Constants.xmrigCCOptionsSharedPrefs,
        jsonEncode({
          "xmrigCCServerUrl": _xmrigCCServerUrlFieldController.text,
          "xmrigCCServerToken": _xmrigCCServerTokenFieldController.text,
          "xmrigCCWorkerId": _xmrigCCWorkerIdFieldController.text
        }));
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
          Provider.of<CoinDataProvider>(context, listen: false).threadCount =
              int.tryParse(value);
        }
      },
    );
  }

  Widget _getMinerBackendDropdown(
      MinerBinary selectedMinerBinary, List<String> supportedMiningEngines) {
    final minerBinaries = getSupportedMinerBinaries(supportedMiningEngines);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<MinerBinary>(
            isExpanded: true,
            decoration: const InputDecoration(labelText: "Miner Backend"),
            value: selectedMinerBinary,
            items: minerBinaries
                .map<DropdownMenuItem<MinerBinary>>(
                    (MinerBinary minerBinary) => DropdownMenuItem<MinerBinary>(
                          child: Text(minerBinary.name),
                          value: minerBinary,
                        ))
                .toList(),
            onChanged: (MinerBinary? minerBinary) {
              if (minerBinary != null) {
                if (MatomoTracker.instance.initialized) {
                  MatomoTracker.instance.trackEvent(
                      eventCategory: "CoinData Wizard",
                      action: "Selected Mining Engine",
                      eventName: minerBinary.name);
                }
                Provider.of<CoinDataProvider>(context, listen: false)
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
          decoration: const InputDecoration(labelText: "xmrigCC Server URL"),
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

  @override
  Widget build(BuildContext context) {
    final coinDataProvider = Provider.of<CoinDataProvider>(context);
    final selectedMinerBinary = coinDataProvider.selectedMinerBinary;
    final supportedMiningEngines =
        coinDataProvider.selectedCoinData!.supportedMiningEngines;

    return Form(
        key: _miningEngineFormKey,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Select Mining Engine",
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(
                height: 8,
              ),
              Expanded(
                  child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _getMinerBackendDropdown(
                      selectedMinerBinary, supportedMiningEngines),
                  const SizedBox(
                    height: 8,
                  ),
                  if (selectedMinerBinary == MinerBinary.xmrigCC) ...[
                    _getXmrigCCOptions(),
                    const SizedBox(
                      height: 8,
                    )
                  ],
                  _getThreadCountInput()
                ],
              )),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton(
                      onPressed: () {
                        if (MatomoTracker.instance.initialized) {
                          MatomoTracker.instance.trackEvent(
                            eventCategory: "CoinData Wizard",
                            action: "Pressed Previous - MiningEngine",
                          );
                        }
                        widget.setCurrentCoinDataWizardStep(
                            CoinDataWizardStep.walletAddressInput);
                      },
                      style: ElevatedButton.styleFrom(
                          shape: const StadiumBorder(),
                          shadowColor: Colors.transparent),
                      child: const Icon(
                        Icons.arrow_back,
                        size: 16,
                      )),
                  ElevatedButton(
                      onPressed: () {
                        if (_miningEngineFormKey.currentState!.validate()) {
                          _miningEngineFormKey.currentState!.save();
                          _saveXmrigCCOptions();
                          if (MatomoTracker.instance.initialized) {
                            MatomoTracker.instance.trackEvent(
                                eventCategory: "CoinData Wizard",
                                action: "Pressed Done - MiningEngine");
                          }
                          widget.setCurrentCoinDataWizardStep(null);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                          shape: const StadiumBorder(),
                          shadowColor: Colors.transparent),
                      child: const Icon(
                        Icons.check,
                        size: 16,
                      ))
                ],
              )
            ],
          ),
        ));
  }
}
