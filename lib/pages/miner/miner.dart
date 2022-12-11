import 'dart:convert';
import 'dart:io';

import 'package:ekatapoolcompanion/models/coindata.dart';
import 'package:ekatapoolcompanion/models/minerconfig.dart';
import 'package:ekatapoolcompanion/pages/miner/android_miner.dart';
import 'package:ekatapoolcompanion/pages/miner/coindatas.dart';
import 'package:ekatapoolcompanion/pages/miner/desktop_miner.dart';
import 'package:ekatapoolcompanion/pages/miner/final_miner_config.dart';
import 'package:ekatapoolcompanion/pages/miner/miner_support.dart';
import 'package:ekatapoolcompanion/providers/minerstatus.dart';
import 'package:ekatapoolcompanion/utils/common.dart';
import 'package:ekatapoolcompanion/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:matomo_tracker/matomo_tracker.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum WizardStep { coinNameSelect, walletAddressInput, minerConfig, miner }

class Miner extends StatefulWidget {
  const Miner({Key? key}) : super(key: key);

  @override
  State<Miner> createState() => _MinerState();
}

class _MinerState extends State<Miner> {
  final _walletAddressFormKey = GlobalKey<FormState>();
  final _walletAddressFieldController = TextEditingController();
  WizardStep _currentWizardStep = WizardStep.coinNameSelect;

  @override
  void initState() {
    super.initState();
    if (MatomoTracker.instance.initialized) {
      MatomoTracker.instance
          .trackEvent(eventCategory: 'Page Change', action: 'Miner');
    }
    MinerConfig? minerConfig =
        Provider.of<MinerStatusProvider>(context, listen: false).minerConfig;
    var coinData = getCoinDataFromMinerConfig(minerConfig);
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
      final minerConfig =
          Provider.of<MinerStatusProvider>(context, listen: false).minerConfig;
      if (addresses.isNotEmpty) {
        final address = addresses.first;
        minerConfig?.pools.first.user = address["address"];
        Provider.of<MinerStatusProvider>(context, listen: false).minerConfig =
            minerConfig;
        _walletAddressFieldController.text = address["address"];
      } else {
        minerConfig?.pools.first.user = "";
        Provider.of<MinerStatusProvider>(context, listen: false).minerConfig =
            minerConfig;
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
      final minerConfig =
          Provider.of<MinerStatusProvider>(context, listen: false).minerConfig;
      if (minerConfig != null && minerConfig.pools.isNotEmpty) {
        minerConfig.pools.first.user = walletAddress;
        Provider.of<MinerStatusProvider>(context, listen: false).minerConfig =
            minerConfig;
      }
    }
  }

  Widget _buildWalletAddressAndThreadCountInputForm(CoinData? coinData) {
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
                  _saveWalletAddress(
                      coinData.coinName.toLowerCase(), address.trim());
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
                            setState(() {
                              _currentWizardStep = WizardStep.coinNameSelect;
                            });
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
                            setState(() {
                              _currentWizardStep = WizardStep.minerConfig;
                            });
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

  Widget _showWalletAddressInput(
      CoinData? coinData, MinerConfig? currentlyMining) {
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
              coinData.coinName,
              style: TextStyle(
                  fontSize: 24, color: Theme.of(context).primaryColor),
            )
          ],
        ),
        const SizedBox(
          height: 8,
        ),
        _buildWalletAddressAndThreadCountInputForm(coinData),
        const SizedBox(
          height: 8,
        ),
        _showCurrentlyMining(currentlyMining)
      ],
    );
  }

  Widget _showCoinSelectInput(MinerConfig? currentlyMining, String? gpuVendor) {
    var deviceHasGPU = gpuVendor != null;
    var _coinDatas = deviceHasGPU
        ? coinDatas
        : coinDatas.where((coinData) => coinData.cpuMineable);
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
              itemHeight: null,
              isExpanded: true,
              hint: const Text("Select coin"),
              style: TextStyle(color: Theme.of(context).primaryColor),
              items: _coinDatas
                  .map<DropdownMenuItem<CoinData>>(
                      (CoinData coinData) => DropdownMenuItem<CoinData>(
                          value: coinData,
                          child: Column(
                            children: [
                              const SizedBox(
                                height: 8,
                              ),
                              Row(
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
                              ),
                              const SizedBox(
                                height: 4,
                              ),
                              DefaultTextStyle(
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: Theme.of(context).primaryColor),
                                  child: Row(
                                    children: [
                                      const Text("Host:"),
                                      deviceHasGPU
                                          ? Text(
                                              "${coinData.poolAddress}:${coinData.poolPortGPU}")
                                          : Text(
                                              "${coinData.poolAddress}:${coinData.poolPortCPU}")
                                    ],
                                  )),
                              const SizedBox(
                                height: 4,
                              ),
                              DefaultTextStyle(
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: Theme.of(context).primaryColor),
                                  child: Row(
                                    children: [
                                      const Text("Algo:"),
                                      Text(coinData.coinAlgo)
                                    ],
                                  )),
                              const SizedBox(
                                height: 8,
                              ),
                            ],
                          )))
                  .toList(),
              onChanged: (CoinData? coinData) {
                _loadWalletAddress(coinData!.coinName.toLowerCase());
                MinerConfig minerConfig = MinerConfig(pools: [
                  Pool(
                      algo: coinData.coinAlgo,
                      url:
                          "${coinData.poolAddress}:${deviceHasGPU ? coinData.poolPortGPU : coinData.poolPortCPU}",
                      user: "")
                ]);
                if (deviceHasGPU) {
                  if (gpuVendor.toLowerCase() == "nvidia") {
                    minerConfig.cuda = Gpu(enabled: true);
                  }
                  if (gpuVendor.toLowerCase() == "amd") {
                    minerConfig.opencl = Gpu(enabled: true);
                  }
                } else {
                  minerConfig.cpu = Cpu(enabled: true);
                }
                Provider.of<MinerStatusProvider>(context, listen: false)
                    .minerConfig = minerConfig;
                setState(() {
                  _currentWizardStep = WizardStep.walletAddressInput;
                });
              }),
        ),
        const SizedBox(
          height: 8,
        ),
        OutlinedButton(
            onPressed: () {
              setState(() {
                _currentWizardStep = WizardStep.minerConfig;
              });
            },
            child: const Text("Use custom config")),
        const SizedBox(
          height: 8,
        ),
        _showCurrentlyMining(currentlyMining)
      ],
    );
  }

  Widget _showCurrentlyMining(MinerConfig? currentlyMiningMinerConfig) {
    var coinData = getCoinDataFromMinerConfig(currentlyMiningMinerConfig);
    return currentlyMiningMinerConfig != null
        ? Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (coinData != null) ...[
                Text("Currently Mining: ${coinData.coinName}"),
                const SizedBox(
                  width: 8,
                ),
                Image(
                  image: AssetImage(coinData.coinLogoPath),
                  width: 24,
                  height: 24,
                ),
              ] else
                Text(
                    "Currently Mining: ${currentlyMiningMinerConfig.pools.first.algo}"),
              const SizedBox(
                width: 16,
              ),
              OutlinedButton(
                  onPressed: () {
                    Provider.of<MinerStatusProvider>(context, listen: false)
                        .minerConfig = currentlyMiningMinerConfig;
                    setState(() {
                      _currentWizardStep = WizardStep.miner;
                    });
                  },
                  child: const Text("Show"))
            ],
          )
        : Container();
  }

  Widget _getMiner(
      String? minerConfigPath, ValueChanged<WizardStep> setCurrentWizardStep,
      [int? threadCount]) {
    return Platform.isAndroid
        ? AndroidMiner(
            minerConfigPath: minerConfigPath!,
            setCurrentWizardStep: setCurrentWizardStep,
            threadCount: threadCount,
          )
        : Platform.isLinux || Platform.isWindows
            ? DesktopMiner(
                minerConfigPath: minerConfigPath!,
                setCurrentWizardStep: setCurrentWizardStep,
                threadCount: threadCount,
              )
            : const MinerSupport();
  }

  Widget _getCurrentWizard(
      WizardStep wizardStep,
      MinerConfig? currentlyMining,
      String? gpuVendor,
      CoinData? coinData,
      int? threadCount,
      String? minerConfigPath) {
    switch (wizardStep) {
      case WizardStep.coinNameSelect:
        return _showCoinSelectInput(currentlyMining, gpuVendor);
      case WizardStep.walletAddressInput:
        return _showWalletAddressInput(coinData, currentlyMining);
      case WizardStep.minerConfig:
        return FinalMinerConfig(
          setCurrentWizardStep: (WizardStep wizardStep) => setState(() {
            _currentWizardStep = wizardStep;
          }),
        );
      case WizardStep.miner:
        return _getMiner(
            minerConfigPath,
            (WizardStep wizardStep) => setState(() {
                  _currentWizardStep = wizardStep;
                }),
            threadCount);
      default:
        return _showCoinSelectInput(currentlyMining, gpuVendor);
    }
  }

  @override
  Widget build(BuildContext context) {
    MinerConfig? minerConfig =
        Provider.of<MinerStatusProvider>(context).minerConfig;
    MinerConfig? currentlyMiningMinerConfig =
        Provider.of<MinerStatusProvider>(context).currentlyMiningMinerConfig;
    int? threadCount =
        Provider.of<MinerStatusProvider>(context, listen: false).threadCount;
    String? gpuVendor =
        Provider.of<MinerStatusProvider>(context, listen: false).gpuVendor;
    String? minerConfigPath =
        Provider.of<MinerStatusProvider>(context).minerConfigPath;

    final coinData = getCoinDataFromMinerConfig(minerConfig);

    // return coinData == null
    //     ? _showCoinSelectInput(currentlyMiningMinerConfig, gpuVendor)
    //     : minerConfig != null && showMinerScreen
    //         ? _getMiner(coinData, minerConfig.pools.first.user,
    //             threadCount: threadCount, gpuVendor: gpuVendor)
    //         : _showWalletAddressInput(coinData, currentlyMiningMinerConfig);
    return _getCurrentWizard(_currentWizardStep, currentlyMiningMinerConfig,
        gpuVendor, coinData, threadCount, minerConfigPath);
  }
}
