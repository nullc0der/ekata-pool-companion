import 'dart:convert';
import 'dart:io';

import 'package:ekatapoolcompanion/models/coindata.dart';
import 'package:ekatapoolcompanion/pages/miner/android_miner.dart';
import 'package:ekatapoolcompanion/pages/miner/coindatas.dart';
import 'package:ekatapoolcompanion/pages/miner/desktop_miner.dart';
import 'package:ekatapoolcompanion/pages/miner/miner_support.dart';
import 'package:ekatapoolcompanion/providers/MinerStatus.dart';
import 'package:ekatapoolcompanion/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:matomo_tracker/matomo_tracker.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Miner extends StatefulWidget {
  const Miner({Key? key}) : super(key: key);

  @override
  State<Miner> createState() => _MinerState();
}

class _MinerState extends State<Miner> {
  final _walletAddressFormKey = GlobalKey<FormState>();
  final _walletAddressFieldController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (MatomoTracker.instance.initialized) {
      MatomoTracker.instance
          .trackEvent(eventCategory: 'Page Change', action: 'Miner');
    }
    CoinData? coinData =
        Provider.of<MinerStatusProvider>(context, listen: false).coinData;
    if (coinData != null) {
      _loadWalletAddress(coinData.coinName.toLowerCase());
    }
  }

  @override
  void dispose() {
    _walletAddressFieldController.dispose();
    super.dispose();
  }

  Future<void> _loadWalletAddress(String coinName) async {
    final prefs = await SharedPreferences.getInstance();
    String walletAddresses =
        prefs.getString(Constants.walletAddressesKeySharedPrefs) ?? "";
    if (walletAddresses.isNotEmpty) {
      var addressesJson = jsonDecode(walletAddresses);
      var addresses = addressesJson.where((address) =>
          address["coinName"].toLowerCase() == coinName.toLowerCase());
      if (addresses.isNotEmpty) {
        var address = addresses.first;
        Provider.of<MinerStatusProvider>(context, listen: false).walletAddress =
            address['address'];
        _walletAddressFieldController.text = address["address"];
      } else {
        Provider.of<MinerStatusProvider>(context, listen: false).walletAddress =
            "";
        _walletAddressFieldController.text = "";
      }
    }
  }

  Future<void> _saveWalletAddress(String coinName, String walletAddress) async {
    final prefs = await SharedPreferences.getInstance();
    if (walletAddress.isNotEmpty) {
      String walletAddresses =
          prefs.getString(Constants.walletAddressesKeySharedPrefs) ?? "";
      if (walletAddresses.isNotEmpty) {
        var addressesJson = jsonDecode(walletAddresses);
        var addresses = addressesJson.where((address) =>
            address["coinName"].toLowerCase() == coinName.toLowerCase());
        if (addresses.isNotEmpty) {
          var address = addresses.first;
          var index = addressesJson.indexOf(address);
          address["address"] = walletAddress;
          addressesJson[index] = address;
        } else {
          var address = {
            "coinName": coinName.toLowerCase(),
            "address": walletAddress
          };
          addressesJson.add(address);
        }
        prefs.setString(
            Constants.walletAddressesKeySharedPrefs, jsonEncode(addressesJson));
      } else {
        var addressesJson = [
          {"coinName": coinName.toLowerCase(), "address": walletAddress}
        ];
        prefs.setString(
            Constants.walletAddressesKeySharedPrefs, jsonEncode(addressesJson));
      }
      Provider.of<MinerStatusProvider>(context, listen: false).walletAddress =
          walletAddress;
    }
  }

  Widget _buildWalletAddressInputForm(CoinData? coinData) {
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
                if (address != null && coinData != null) {
                  _saveWalletAddress(coinData.coinName.toLowerCase(), address);
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
                                .coinData = null;
                            Provider.of<MinerStatusProvider>(context,
                                    listen: false)
                                .walletAddress = "";
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
                            Provider.of<MinerStatusProvider>(context,
                                    listen: false)
                                .startMiningPressed = true;
                          }
                        },
                        child: const Text("Start Mining")),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _showWalletAddressInput(CoinData? coinData) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
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
            Image(
              image: AssetImage(coinData!.coinLogoPath),
              width: 24,
              height: 24,
            ),
            Text(
              coinData!.coinName,
              style: TextStyle(
                  fontSize: 24, color: Theme.of(context).primaryColor),
            )
          ],
        ),
        const SizedBox(
          height: 8,
        ),
        _buildWalletAddressInputForm(coinData)
      ],
    );
  }

  Widget _showCoinSelectInput() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: double.infinity,
          child: Text(
            "Select the coin you want to mine",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              color: Theme.of(context).primaryColor,
            ),
          ),
        ),
        const SizedBox(
          height: 8,
        ),
        SizedBox(
          width: 300,
          child: DropdownButton<CoinData>(
              isExpanded: true,
              hint: const Text("Select coin"),
              style: TextStyle(color: Theme.of(context).primaryColor),
              items: coinDatas
                  .map<DropdownMenuItem<CoinData>>(
                      (CoinData coinData) => DropdownMenuItem<CoinData>(
                          value: coinData,
                          child: Row(
                            children: [
                              Image(
                                image: AssetImage(coinData.coinLogoPath),
                                width: 24,
                                height: 24,
                              ),
                              const SizedBox(
                                width: 8,
                              ),
                              Text(coinData.coinName)
                            ],
                          )))
                  .toList(),
              onChanged: (CoinData? coinData) {
                _loadWalletAddress(coinData!.coinName.toLowerCase());
                Provider.of<MinerStatusProvider>(context, listen: false)
                    .startMiningPressed = false;
                Provider.of<MinerStatusProvider>(context, listen: false)
                    .coinData = coinData;
              }),
        )
      ],
    );
  }

  Widget _getMiner(CoinData coinData, String walletAddress) {
    return Platform.isAndroid
        ? AndroidMiner(
            coinData: coinData,
            walletAddress: walletAddress,
          )
        : Platform.isLinux || Platform.isWindows
            ? DesktopMiner(
                coinData: coinData,
                walletAddress: walletAddress,
              )
            : const MinerSupport();
  }

  @override
  Widget build(BuildContext context) {
    CoinData? coinData = Provider.of<MinerStatusProvider>(context).coinData;
    String walletAddress =
        Provider.of<MinerStatusProvider>(context).walletAddress;
    bool isMining = Provider.of<MinerStatusProvider>(context).isMining;
    bool startMiningPressed =
        Provider.of<MinerStatusProvider>(context).startMiningPressed;
    return isMining
        ? _getMiner(coinData!, walletAddress)
        : coinData == null
            ? _showCoinSelectInput()
            : walletAddress.isNotEmpty && startMiningPressed
                ? _getMiner(coinData, walletAddress)
                : _showWalletAddressInput(coinData);
  }
}
