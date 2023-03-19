import 'dart:convert';

import 'package:ekatapoolcompanion/models/coindata.dart';
import 'package:ekatapoolcompanion/models/minerconfig.dart';
import 'package:ekatapoolcompanion/pages/miner/currentlymining.dart';
import 'package:ekatapoolcompanion/pages/miner/miner.dart';
import 'package:ekatapoolcompanion/providers/minerstatus.dart';
import 'package:ekatapoolcompanion/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WalletAddress extends StatefulWidget {
  const WalletAddress({Key? key, required this.setCurrentWizardStep})
      : super(key: key);

  final ValueChanged<WizardStep> setCurrentWizardStep;

  @override
  State<WalletAddress> createState() => _WalletAddressState();
}

class _WalletAddressState extends State<WalletAddress> {
  final _walletAddressFormKey = GlobalKey<FormState>();
  final _walletAddressFieldController = TextEditingController();

  @override
  void initState() {
    super.initState();
    MinerConfig? minerConfig =
        Provider.of<MinerStatusProvider>(context, listen: false).minerConfig;
    if (minerConfig != null) {
      _loadWalletAddress(minerConfig.pools.first.url);
    }
  }

  @override
  void dispose() {
    _walletAddressFieldController.dispose();
    super.dispose();
  }

  Future<void> _loadWalletAddress(String poolAddress) async {
    final prefs = await SharedPreferences.getInstance();
    String walletAddresses =
        prefs.getString(Constants.walletAddressesKeySharedPrefs) ?? "";
    if (walletAddresses.isNotEmpty) {
      var addressesJson = jsonDecode(walletAddresses);
      var addresses = addressesJson
          .where((address) => address["poolAddress"] == poolAddress);
      final minerConfig =
          Provider.of<MinerStatusProvider>(context, listen: false).minerConfig;
      if (addresses.isNotEmpty) {
        final address = addresses.first;
        minerConfig?.pools.first.user = address["walletAddress"];
        Provider.of<MinerStatusProvider>(context, listen: false).minerConfig =
            minerConfig;
        _walletAddressFieldController.text = address["walletAddress"];
      } else {
        minerConfig?.pools.first.user = "";
        Provider.of<MinerStatusProvider>(context, listen: false).minerConfig =
            minerConfig;
        _walletAddressFieldController.text = "";
      }
    }
  }

  Future<void> _saveWalletAddress(
      String poolAddress, String walletAddress) async {
    final prefs = await SharedPreferences.getInstance();
    if (walletAddress.isNotEmpty) {
      String walletAddresses =
          prefs.getString(Constants.walletAddressesKeySharedPrefs) ?? "";
      if (walletAddresses.isNotEmpty) {
        var addressesJson = jsonDecode(walletAddresses);
        var addresses = addressesJson
            .where((address) => address["poolAddress"] == poolAddress);
        if (addresses.isNotEmpty) {
          var address = addresses.first;
          var index = addressesJson.indexOf(address);
          address["walletAddress"] = walletAddress;
          addressesJson[index] = address;
        } else {
          var address = {
            "poolAddress": poolAddress,
            "walletAddress": walletAddress
          };
          addressesJson.add(address);
        }
        prefs.setString(
            Constants.walletAddressesKeySharedPrefs, jsonEncode(addressesJson));
      } else {
        var addressesJson = [
          {"poolAddress": poolAddress, "walletAddress": walletAddress}
        ];
        prefs.setString(
            Constants.walletAddressesKeySharedPrefs, jsonEncode(addressesJson));
      }
      final minerConfig =
          Provider.of<MinerStatusProvider>(context, listen: false).minerConfig;
      if (minerConfig != null && minerConfig.pools.isNotEmpty) {
        minerConfig.pools.first.user = walletAddress;
        Provider.of<MinerStatusProvider>(context, listen: false).minerConfig =
            minerConfig;
      }
    }
  }

  Widget _buildWalletAddressAndThreadCountInputForm(MinerConfig? minerConfig) {
    return Form(
      key: _walletAddressFormKey,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          children: [
            TextFormField(
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return "Wallet address can't be empty";
                }
                return null;
              },
              controller: _walletAddressFieldController,
              decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: "Enter wallet address"),
              onSaved: (address) {
                if (address != null && minerConfig != null) {
                  _saveWalletAddress(
                      minerConfig.pools.first.url, address.trim());
                }
              },
            ),
            const SizedBox(
              height: 8.0,
            ),
            TextFormField(
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
                  hintText: "Enter Thread Count(Optional)"),
              onSaved: (value) {
                if (value != null &&
                    int.tryParse(value) != null &&
                    int.tryParse(value)! > 0) {
                  Provider.of<MinerStatusProvider>(context, listen: false)
                      .threadCount = int.tryParse(value);
                }
              },
            ),
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
                          child: const Text("Select Coin"))),
                  const SizedBox(
                    width: 8,
                  ),
                  Expanded(
                    child: ElevatedButton(
                        style: ButtonStyle(
                            backgroundColor: MaterialStateProperty.all(
                                Colors.green.shade900)),
                        onPressed: () {
                          if (_walletAddressFormKey.currentState!.validate()) {
                            _walletAddressFormKey.currentState!.save();
                            widget.setCurrentWizardStep(WizardStep.minerConfig);
                          }
                        },
                        child: const Text("Show final config")),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    CoinData? coinData = Provider.of<MinerStatusProvider>(context).coinData;
    MinerConfig? minerConfig =
        Provider.of<MinerStatusProvider>(context).minerConfig;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (coinData != null)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Wallet address for",
                style: TextStyle(
                    fontSize: 24, color: Theme.of(context).primaryColor),
              ),
              const SizedBox(
                width: 8,
              ),
              Image.network(
                coinData.coinLogoUrl,
                width: 24,
                height: 24,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.close_rounded,
                  color: Color(0xFF273951),
                ),
              ),
              Text(
                coinData.coinName,
                style: TextStyle(
                    fontSize: 24, color: Theme.of(context).primaryColor),
              )
            ],
          ),
        const SizedBox(
          height: 8,
        ),
        _buildWalletAddressAndThreadCountInputForm(minerConfig),
        const SizedBox(
          height: 8,
        ),
        CurrentlyMining(setCurrentWizardStep: widget.setCurrentWizardStep)
      ],
    );
  }
}
