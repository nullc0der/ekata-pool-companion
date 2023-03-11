import 'dart:convert';
import 'dart:io';

import 'package:ekatapoolcompanion/models/coindata.dart';
import 'package:ekatapoolcompanion/models/minerconfig.dart';
import 'package:ekatapoolcompanion/pages/miner/android_miner.dart';
import 'package:ekatapoolcompanion/pages/miner/coindatas.dart';
import 'package:ekatapoolcompanion/pages/miner/desktop_miner.dart';
import 'package:ekatapoolcompanion/pages/miner/final_miner_config.dart';
import 'package:ekatapoolcompanion/pages/miner/miner_support.dart';
import 'package:ekatapoolcompanion/pages/miner/user_miner_config.dart';
import 'package:ekatapoolcompanion/providers/minerstatus.dart';
import 'package:ekatapoolcompanion/utils/common.dart';
import 'package:ekatapoolcompanion/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:matomo_tracker/matomo_tracker.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum WizardStep {
  coinNameSelect,
  walletAddressInput,
  minerConfig,
  usersMinerConfigs,
  miner
}

class Miner extends StatefulWidget {
  const Miner({Key? key}) : super(key: key);

  @override
  State<Miner> createState() => _MinerState();
}

class _MinerState extends State<Miner> {
  final _walletAddressFormKey = GlobalKey<FormState>();
  final _walletAddressFieldController = TextEditingController();
  WizardStep _currentWizardStep = WizardStep.coinNameSelect;
  int? _selectedCoinIndex;

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
          {
            "poolAddress": poolAddress.toLowerCase(),
            "walletAddress": walletAddress
          }
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

  void _setCurrentWizardStep(WizardStep wizardStep) {
    setState(() {
      _currentWizardStep = wizardStep;
    });
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
                            _setCurrentWizardStep(WizardStep.coinNameSelect);
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
                            _setCurrentWizardStep(WizardStep.minerConfig);
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

  Widget _showCoinSelect(MinerConfig? currentlyMining, String? gpuVendor) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _showCoinSelectInput(gpuVendor),
        if (_selectedCoinIndex != null) ...[
          const SizedBox(
            height: 8,
          ),
          _showPoolSelectInput(gpuVendor)
        ],
        const SizedBox(
          height: 8,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            OutlinedButton(
                onPressed: () {
                  _setCurrentWizardStep(WizardStep.minerConfig);
                },
                child: const Text("Use custom config")),
            const SizedBox(
              width: 8,
            ),
            OutlinedButton(
                onPressed: () {
                  _setCurrentWizardStep(WizardStep.usersMinerConfigs);
                },
                child: const Text("Saved configs"))
          ],
        ),
        const SizedBox(
          height: 8,
        ),
        _showCurrentlyMining(currentlyMining)
      ],
    );
  }

  Widget _showCoinSelectInput(String? gpuVendor) {
    var deviceHasGPU = gpuVendor != null;
    var _coinDatas = deviceHasGPU
        ? coinDatas
        : coinDatas.where((coinData) => coinData.cpuMineable);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Select the coin you want to mine",
          style: TextStyle(
            fontSize: 14,
            color: Theme.of(context).primaryColor,
          ),
        ),
        SizedBox(
          width: 300,
          child: DropdownButton<CoinData>(
              itemHeight: null,
              isExpanded: true,
              hint: const Text("Select coin"),
              style: TextStyle(color: Theme.of(context).primaryColor),
              value: _selectedCoinIndex != null
                  ? coinDatas[_selectedCoinIndex!]
                  : null,
              items: _coinDatas
                  .map<DropdownMenuItem<CoinData>>(
                      (CoinData coinData) => DropdownMenuItem<CoinData>(
                          value: coinData,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
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
                                  Text(coinData.coinName),
                                  const SizedBox(
                                    width: 4,
                                  ),
                                  Text(
                                    "(${coinData.coinAlgo})",
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: Theme.of(context).primaryColor),
                                  )
                                ],
                              ),
                              const SizedBox(
                                height: 8,
                              ),
                            ],
                          )))
                  .toList(),
              onChanged: (CoinData? coinData) {
                if (coinData != null) {
                  setState(() {
                    _selectedCoinIndex = coinDatas.indexOf(coinData);
                  });
                }
              }),
        )
      ],
    );
  }

  Widget _showPoolSelectInput(String? gpuVendor) {
    var deviceHasGPU = gpuVendor != null;
    List<CoinPool>? _coinPools;
    CoinData? _coinData;
    if (_selectedCoinIndex != null) {
      _coinData = coinDatas[_selectedCoinIndex!];
      _coinPools = _coinData.coinPools;
    }

    return _coinData != null
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Select the pool where you want to mine ${_coinData.coinName}",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              const SizedBox(
                height: 8,
              ),
              SizedBox(
                width: 300,
                child: DropdownButton<CoinPool>(
                  isExpanded: true,
                  hint: const Text("Select Pool"),
                  style: TextStyle(color: Theme.of(context).primaryColor),
                  items: _coinPools!
                      .map<DropdownMenuItem<CoinPool>>((CoinPool coinPool) =>
                          DropdownMenuItem<CoinPool>(
                              value: coinPool,
                              child: DefaultTextStyle(
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: Theme.of(context).primaryColor),
                                  child: Row(
                                    children: [
                                      deviceHasGPU
                                          ? Text(
                                              "${coinPool.poolAddress}:${coinPool.poolPortGPU}")
                                          : Text(
                                              "${coinPool.poolAddress}:${coinPool.poolPortCPU}")
                                    ],
                                  ))))
                      .toList(),
                  onChanged: (CoinPool? coinPool) {
                    if (coinPool != null) {
                      _loadWalletAddress(
                          "${coinPool.poolAddress}:${deviceHasGPU ? coinPool.poolPortGPU : coinPool.poolPortCPU}");
                      MinerConfig minerConfig = MinerConfig(pools: [
                        Pool(
                            algo: _coinData!.coinAlgo,
                            url:
                                "${coinPool.poolAddress}:${deviceHasGPU ? coinPool.poolPortGPU : coinPool.poolPortCPU}",
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
                      _setCurrentWizardStep(WizardStep.walletAddressInput);
                    }
                  },
                ),
              )
            ],
          )
        : Column();
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
                    _setCurrentWizardStep(WizardStep.miner);
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
        return _showCoinSelect(currentlyMining, gpuVendor);
      case WizardStep.walletAddressInput:
        return _showWalletAddressInput(coinData, currentlyMining);
      case WizardStep.minerConfig:
        return FinalMinerConfig(
          setCurrentWizardStep: _setCurrentWizardStep,
        );
      case WizardStep.usersMinerConfigs:
        return UserMinerConfig(
          setCurrentWizardStep: _setCurrentWizardStep,
        );
      case WizardStep.miner:
        return _getMiner(minerConfigPath, _setCurrentWizardStep, threadCount);
      default:
        return _showCoinSelect(currentlyMining, gpuVendor);
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
