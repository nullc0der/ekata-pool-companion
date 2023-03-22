import 'dart:convert';

import 'package:ekatapoolcompanion/pages/miner/coindata/coindatawidget.dart';
import 'package:ekatapoolcompanion/providers/coindata.dart';
import 'package:ekatapoolcompanion/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WalletAddress extends StatefulWidget {
  const WalletAddress({Key? key, required this.setCurrentCoinDataWizardStep})
      : super(key: key);

  final ValueChanged<CoinDataWizardStep?> setCurrentCoinDataWizardStep;

  @override
  State<WalletAddress> createState() => _WalletAddressState();
}

class _WalletAddressState extends State<WalletAddress> {
  final _walletAddressFormKey = GlobalKey<FormState>();
  final _walletAddressFieldController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final coinDataProvider =
        Provider.of<CoinDataProvider>(context, listen: false);
    if (coinDataProvider.selectedPoolUrl != null &&
        coinDataProvider.selectedPoolPort != null) {
      _loadWalletAddress(
          "${coinDataProvider.selectedPoolUrl}:${coinDataProvider.selectedPoolPort}");
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
      if (addresses.isNotEmpty) {
        final address = addresses.first;
        Provider.of<CoinDataProvider>(context, listen: false).walletAddress =
            address["walletAddress"];
        _walletAddressFieldController.text = address["walletAddress"];
      } else {
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
      Provider.of<CoinDataProvider>(context, listen: false).walletAddress =
          walletAddress;
    }
  }

  @override
  Widget build(BuildContext context) {
    final coinDataProvider = Provider.of<CoinDataProvider>(context);

    return Form(
        key: _walletAddressFormKey,
        child: Padding(
            padding: const EdgeInsets.all(8),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                "Enter Wallet Address",
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(
                height: 8,
              ),
              Expanded(
                  child: Container(
                alignment: Alignment.center,
                child: TextFormField(
                  maxLines: null,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Wallet address can't be empty";
                    }
                    return null;
                  },
                  controller: _walletAddressFieldController,
                  decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: "Enter wallet address"),
                  onSaved: (address) {
                    if (address != null &&
                        coinDataProvider.selectedPoolUrl != null &&
                        coinDataProvider.selectedPoolPort != null) {
                      _saveWalletAddress(
                          "${coinDataProvider.selectedPoolUrl}:${coinDataProvider.selectedPoolPort}",
                          address.trim());
                    }
                  },
                ),
              )),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  OutlinedButton(
                      onPressed: () {
                        Provider.of<CoinDataProvider>(context, listen: false)
                            .walletAddress = "";
                        widget.setCurrentCoinDataWizardStep(
                            CoinDataWizardStep.portSelect);
                      },
                      child: const Text("Select Pool Port")),
                  ElevatedButton(
                      onPressed: () {
                        if (_walletAddressFormKey.currentState!.validate()) {
                          _walletAddressFormKey.currentState!.save();
                          widget.setCurrentCoinDataWizardStep(
                              CoinDataWizardStep.miningEngineSelect);
                        }
                      },
                      child: const Text("Select mining engine"))
                ],
              )
            ])));
  }
}
