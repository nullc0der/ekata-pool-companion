import 'dart:convert';

import 'package:ekatapoolcompanion/pages/miner/coindata/coindatawidget.dart';
import 'package:ekatapoolcompanion/providers/coindata.dart';
import 'package:ekatapoolcompanion/utils/common.dart';
import 'package:ekatapoolcompanion/utils/constants.dart';
import 'package:ekatapoolcompanion/utils/desktop_miner/miner.dart';
import 'package:ekatapoolcompanion/widgets/passwordtextformfield.dart';
import 'package:flutter/material.dart';
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
  final _xmrigCCServerUrlFieldController = TextEditingController();
  final _xmrigCCServerTokenFieldController = TextEditingController();
  final _xmrigCCWorkerIdFieldController = TextEditingController();
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
      validator: (value) {
        if (value != null && value.isNotEmpty) {
          if (int.tryParse(value) == null) {
            return "Make sure to enter numeric value";
          }
          if (int.tryParse(value)! < 0) {
            return "Make sure to enter a value greater than 0";
          }
        }
        return null;
      },
      keyboardType: TextInputType.number,
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
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

  Widget _getMinerBackendDropdown(MinerBinary selectedMinerBinary) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<MinerBinary>(
            isExpanded: true,
            decoration: const InputDecoration(
                border: OutlineInputBorder(), labelText: "Miner Backend"),
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
          decoration: const InputDecoration(
              border: OutlineInputBorder(), labelText: "xmrigCC Server url"),
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
          decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: "xmrigCC Worker ID (Optional)"),
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
    final selectedMinerBinary =
        Provider.of<CoinDataProvider>(context).selectedMinerBinary;

    return Form(
        key: _miningEngineFormKey,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Select Mining Engine",
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(
                height: 8,
              ),
              Expanded(
                  child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _getMinerBackendDropdown(selectedMinerBinary),
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
                  OutlinedButton(
                      onPressed: () {
                        widget.setCurrentCoinDataWizardStep(
                            CoinDataWizardStep.walletAddressInput);
                      },
                      child: const Text("Input wallet address")),
                  ElevatedButton(
                      onPressed: () {
                        if (_miningEngineFormKey.currentState!.validate()) {
                          _miningEngineFormKey.currentState!.save();
                          _saveXmrigCCOptions();
                          widget.setCurrentCoinDataWizardStep(null);
                        }
                      },
                      child: const Text("Done"))
                ],
              )
            ],
          ),
        ));
  }
}
