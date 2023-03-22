import 'package:ekatapoolcompanion/pages/miner/coindata/coindatawidget.dart';
import 'package:ekatapoolcompanion/providers/coindata.dart';
import 'package:ekatapoolcompanion/utils/desktop_miner/miner.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
    _xmrigCCServerUrlFieldController.text =
        coinDataProvider.xmrigCCServerUrl ?? "";
    _xmrigCCServerTokenFieldController.text =
        coinDataProvider.xmrigCCServerToken ?? "";
    _xmrigCCWorkerIdFieldController.text =
        coinDataProvider.xmrigCCWorkerId ?? "";
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
            Provider.of<CoinDataProvider>(context, listen: false)
                .xmrigCCServerUrl = value;
          },
        ),
        const SizedBox(
          height: 8.0,
        ),
        TextFormField(
          controller: _xmrigCCServerTokenFieldController,
          obscureText: true,
          enableSuggestions: false,
          autocorrect: false,
          //TODO: IMPORTANT: Review everything done till now
          decoration: const InputDecoration(
              border: OutlineInputBorder(), labelText: "xmrigCC Server token"),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return "Token can't be empty";
            }
            return null;
          },
          onSaved: (value) {
            Provider.of<CoinDataProvider>(context, listen: false)
                .xmrigCCServerToken = value;
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
              Provider.of<CoinDataProvider>(context, listen: false)
                  .xmrigCCWorkerId = value;
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
                  child: Container(
                alignment: Alignment.center,
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
                ),
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
