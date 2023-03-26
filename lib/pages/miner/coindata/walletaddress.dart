import 'dart:convert';

import 'package:ekatapoolcompanion/pages/miner/coindata/coindatawidget.dart';
import 'package:ekatapoolcompanion/providers/coindata.dart';
import 'package:ekatapoolcompanion/utils/common.dart';
import 'package:ekatapoolcompanion/utils/constants.dart';
import 'package:ekatapoolcompanion/widgets/passwordtextformfield.dart';
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
  final _passwordFieldController = TextEditingController();
  final _rigIdFieldController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final coinDataProvider =
        Provider.of<CoinDataProvider>(context, listen: false);
    if (coinDataProvider.selectedPoolUrl != null &&
        coinDataProvider.selectedPoolPort != null) {
      _loadPoolCredentials(
          "${coinDataProvider.selectedPoolUrl}:${coinDataProvider.selectedPoolPort}");
    }
  }

  @override
  void dispose() {
    _walletAddressFieldController.dispose();
    _passwordFieldController.dispose();
    _rigIdFieldController.dispose();
    super.dispose();
  }

  Future<void> _loadPoolCredentials(String poolAddress) async {
    final prefs = await SharedPreferences.getInstance();
    String walletAddresses =
        prefs.getString(Constants.walletAddressesKeySharedPrefs) ?? "";
    if (walletAddresses.isNotEmpty) {
      var addressesJson = jsonDecode(walletAddresses);
      var addresses = addressesJson
          .where((address) => address["poolAddress"] == poolAddress);
      if (addresses.isNotEmpty) {
        final address = addresses.first;
        final rigId = address["rigId"] != null
            ? address["rigId"].isNotEmpty
                ? address["rigId"]
                : getRandomString(6)
            : getRandomString(6);
        Provider.of<CoinDataProvider>(context, listen: false).walletAddress =
            address["walletAddress"];
        Provider.of<CoinDataProvider>(context, listen: false).password =
            address["password"];
        Provider.of<CoinDataProvider>(context, listen: false).rigId = rigId;
        _walletAddressFieldController.text = address["walletAddress"];
        _passwordFieldController.text = address["password"] ?? "";
        _rigIdFieldController.text = rigId;
      } else {
        _rigIdFieldController.text = getRandomString(6);
      }
    } else {
      _rigIdFieldController.text = getRandomString(6);
    }
  }

  Future<void> _savePoolCredentials(String poolAddress) async {
    final prefs = await SharedPreferences.getInstance();
    final walletAddress = _walletAddressFieldController.text;
    final password = _passwordFieldController.text.isNotEmpty
        ? _passwordFieldController.text
        : null;
    final rigId = _rigIdFieldController.text;
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
          address["password"] = password;
          address["rigId"] = rigId;
          addressesJson[index] = address;
        } else {
          var address = {
            "poolAddress": poolAddress,
            "walletAddress": walletAddress,
            "password": password,
            "rigId": rigId
          };
          addressesJson.add(address);
        }
        prefs.setString(
            Constants.walletAddressesKeySharedPrefs, jsonEncode(addressesJson));
      } else {
        var addressesJson = [
          {
            "poolAddress": poolAddress,
            "walletAddress": walletAddress,
            "password": password,
            "rigId": rigId
          }
        ];
        prefs.setString(
            Constants.walletAddressesKeySharedPrefs, jsonEncode(addressesJson));
      }
      Provider.of<CoinDataProvider>(context, listen: false).walletAddress =
          walletAddress;
      Provider.of<CoinDataProvider>(context, listen: false).password = password;
      Provider.of<CoinDataProvider>(context, listen: false).rigId = rigId;
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
                  child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextFormField(
                    maxLines: null,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
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
                        _walletAddressFieldController.text = address.trim();
                      }
                    },
                  ),
                  const SizedBox(
                    height: 8,
                  ),
                  PasswordTextFormField(
                    controller: _passwordFieldController,
                    labelText: "Enter pool password if required",
                    onSaved: (password) {
                      if (password != null &&
                          coinDataProvider.selectedPoolUrl != null &&
                          coinDataProvider.selectedPoolPort != null) {
                        _passwordFieldController.text = password;
                      }
                    },
                  ),
                  const SizedBox(
                    height: 8,
                  ),
                  TextFormField(
                    controller: _rigIdFieldController,
                    decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: "Enter rig id",
                        hintText: "Enter a rig id if the pool supports"),
                    onSaved: (rigId) {
                      if (rigId != null &&
                          coinDataProvider.selectedPoolUrl != null &&
                          coinDataProvider.selectedPoolPort != null) {
                        _rigIdFieldController.text = rigId;
                      }
                    },
                  )
                ],
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
                          _savePoolCredentials(
                              "${coinDataProvider.selectedPoolUrl}:${coinDataProvider.selectedPoolPort}");
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
