import 'dart:convert';

import 'package:ekatapoolcompanion/models/coindata.dart' show CoinData;
import 'package:ekatapoolcompanion/models/minerconfig.dart';
import 'package:ekatapoolcompanion/pages/miner/coindata/coinname.dart';
import 'package:ekatapoolcompanion/pages/miner/coindata/miningengine.dart';
import 'package:ekatapoolcompanion/pages/miner/coindata/poolname.dart';
import 'package:ekatapoolcompanion/pages/miner/coindata/poolport.dart';
import 'package:ekatapoolcompanion/pages/miner/coindata/poolurl.dart';
import 'package:ekatapoolcompanion/pages/miner/coindata/region.dart';
import 'package:ekatapoolcompanion/pages/miner/coindata/walletaddress.dart';
import 'package:ekatapoolcompanion/pages/miner/currentlymining.dart';
import 'package:ekatapoolcompanion/pages/miner/miner.dart';
import 'package:ekatapoolcompanion/providers/coindata.dart';
import 'package:ekatapoolcompanion/providers/minerstatus.dart';
import 'package:ekatapoolcompanion/providers/uistate.dart';
import 'package:ekatapoolcompanion/services/minerconfig.dart';
import 'package:ekatapoolcompanion/utils/common.dart';
import 'package:ekatapoolcompanion/utils/constants.dart';
import 'package:ekatapoolcompanion/utils/desktop_miner/miner.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum CoinDataWizardStep {
  coinNameSelect,
  poolNameSelect,
  regionSelect,
  poolUrlSelect,
  portSelect,
  walletAddressInput,
  miningEngineSelect
}

class CoinDataWidget extends StatefulWidget {
  const CoinDataWidget({Key? key, required this.setCurrentWizardStep})
      : super(key: key);

  final ValueChanged<WizardStep> setCurrentWizardStep;

  @override
  State<CoinDataWidget> createState() => _CoinDataWidgetState();
}

class _CoinDataWidgetState extends State<CoinDataWidget> {
  CoinDataWizardStep? _currentCoinDataWizardStep;
  bool _userUploadedConfigSaving = false;
  bool _userUploadedConfigSaved = false;
  bool _userUploadedConfigSaveHasError = false;
  bool _configSaving = false;

  void _setCurrentCoinDataWizardStep(
      CoinDataWizardStep? currentCoinDataWizardStep) {
    setState(() {
      _currentCoinDataWizardStep = currentCoinDataWizardStep;
    });
  }

  Future<void> _saveMinerConfigInBackend(
      String config, bool userUploaded) async {
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
          setState(() {
            _userUploadedConfigSaving = true;
            _userUploadedConfigSaved = false;
            _userUploadedConfigSaveHasError = false;
          });
          String? minerConfigMd5 = await MinerConfigService.createMinerConfig(
            userId: userId,
            minerConfig: jsonEncode(minerConfig).trim(),
            userUploaded: true,
          );
          if (minerConfigMd5 != null && poolCredentials.isNotEmpty) {
            // NOTE: Check final_miner_config note
            final poolCredentialsPrefs =
                prefs.getString(Constants.poolCredentialsSharedPrefs);
            if (poolCredentialsPrefs != null) {
              final Map<String, dynamic> poolCredentialPrefsDecoded =
                  jsonDecode(poolCredentialsPrefs);
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
            setState(() {
              _userUploadedConfigSaving = false;
              _userUploadedConfigSaved = true;
              _userUploadedConfigSaveHasError = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Saved successfully")));
          }
        } else {
          setState(() {
            _configSaving = true;
          });
          await MinerConfigService.createMinerConfig(
              userId: userId, minerConfig: jsonEncode(minerConfig).trim());
          setState(() {
            _configSaving = false;
          });
        }
      } on Exception catch (_) {
        if (userUploaded) {
          setState(() {
            _userUploadedConfigSaving = false;
            _userUploadedConfigSaved = false;
            _userUploadedConfigSaveHasError = true;
          });
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              backgroundColor: Theme.of(context).colorScheme.error,
              content: Text(
                "There is some error saving at this moment",
                style: TextStyle(color: Theme.of(context).colorScheme.onError),
              )));
        } else {
          setState(() {
            _configSaving = false;
          });
        }
      }
    }
  }

  MinerConfig _getMinerConfig(CoinDataProvider coinDataProvider) {
    String? gpuVendor =
        Provider.of<MinerStatusProvider>(context, listen: false).gpuVendor;
    bool deviceHasGPU = gpuVendor != null;
    MinerConfig minerConfig = MinerConfig(pools: [
      Pool(
          algo: coinDataProvider.selectedCoinData!.coinAlgo,
          url:
              "${coinDataProvider.selectedPoolUrl}:${coinDataProvider.selectedPoolPort}",
          user: coinDataProvider.walletAddress,
          pass: coinDataProvider.password,
          rigId: coinDataProvider.rigId != null &&
                  coinDataProvider.rigId!.isNotEmpty
              ? coinDataProvider.rigId
              : null)
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
    return minerConfig;
  }

  Future<void> _onPressStartMining(CoinDataProvider coinDataProvider) async {
    CoinData? selectedCoinData = coinDataProvider.selectedCoinData;
    if (selectedCoinData != null) {
      final minerConfig = _getMinerConfig(coinDataProvider);
      final minerConfigJSONString = minerConfigToJson(minerConfig);
      await _saveMinerConfigInBackend(minerConfigJSONString, false);
      // TODO: restore debug modes
      if (!kDebugMode) {}
      final filePath = await saveMinerConfigToFile(minerConfigJSONString);
      Provider.of<MinerStatusProvider>(context, listen: false).coinData =
          selectedCoinData;
      Provider.of<MinerStatusProvider>(context, listen: false).minerConfigPath =
          filePath;
      Provider.of<MinerStatusProvider>(context, listen: false).minerConfig =
          minerConfig;
      if (coinDataProvider.threadCount != null) {
        Provider.of<MinerStatusProvider>(context, listen: false).threadCount =
            coinDataProvider.threadCount;
      }
      Provider.of<MinerStatusProvider>(context, listen: false)
          .selectedMinerBinary = coinDataProvider.selectedMinerBinary;
      if (coinDataProvider.selectedMinerBinary == MinerBinary.xmrigCC) {
        Provider.of<MinerStatusProvider>(context, listen: false)
            .xmrigCCServerUrl = coinDataProvider.xmrigCCServerUrl;
        Provider.of<MinerStatusProvider>(context, listen: false)
            .xmrigCCServerToken = coinDataProvider.xmrigCCServerToken;
        Provider.of<MinerStatusProvider>(context, listen: false)
            .xmrigCCWorkerId = coinDataProvider.xmrigCCWorkerId;
      }
      Provider.of<UiStateProvider>(context, listen: false)
          .minerConfigPageShowMinerEngineSelect = false;
      widget.setCurrentWizardStep(WizardStep.miner);
    }
  }

  Widget _showOneCoinData(
      String label, List<String> content, CoinDataWizardStep coinDataWizardStep,
      {required Widget prefixIconOrImage, Widget? subContent}) {
    return InkWell(
      onTap: () {
        _setCurrentCoinDataWizardStep(coinDataWizardStep);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        margin: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  child: prefixIconOrImage,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle, color: Colors.grey.shade300),
                ),
                const SizedBox(
                  width: 8,
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    if (content.isNotEmpty)
                      ...content.map((e) => e.isNotEmpty
                          ? Container(
                              margin: const EdgeInsets.only(top: 2),
                              child: Text(
                                e,
                                style: Theme.of(context).textTheme.labelMedium,
                              ),
                            )
                          : Container())
                  ],
                ),
                // const Spacer(),
                // const Icon(
                //   FontAwesome5.pencil_alt,
                //   size: 18,
                //   color: Color(0xFF273951),
                // )
              ],
            ),
            if (subContent != null)
              Padding(
                padding: const EdgeInsets.only(left: 36),
                child: subContent,
              )
          ],
        ),
      ),
    );
  }

  Widget _showSelectedCoinData(CoinDataProvider coinDataProvider) {
    final selectedCoinData = coinDataProvider.selectedCoinData;
    final selectedPool = coinDataProvider.selectedPoolName;
    final selectedRegion = coinDataProvider.selectedRegion;
    final selectedPoolUrl = coinDataProvider.selectedPoolUrl;
    final selectedPoolPort = coinDataProvider.selectedPoolPort;
    final walletAddress = coinDataProvider.walletAddress;
    final selectedMinerBinary = coinDataProvider.selectedMinerBinary;

    return Card(
      shadowColor: Colors.transparent,
      child: Column(
        children: [
          if (selectedCoinData != null) ...[
            _showOneCoinData(
              "Coin/Token Name",
              [selectedCoinData.coinName],
              CoinDataWizardStep.coinNameSelect,
              prefixIconOrImage: ClipOval(
                child: SizedBox.fromSize(
                  size: const Size.fromRadius(9),
                  child: Image.network(
                    selectedCoinData.coinLogoUrl,
                    width: 18,
                    height: 18,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.close_rounded,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
            if (selectedPool != null)
              _showOneCoinData("Pool Name", [selectedPool],
                  CoinDataWizardStep.poolNameSelect,
                  prefixIconOrImage: const Icon(
                    Icons.group,
                    size: 16,
                    color: Color(0xFF273951),
                  )),
            if (selectedRegion != null)
              _showOneCoinData("Pool Region", [selectedRegion],
                  CoinDataWizardStep.regionSelect,
                  prefixIconOrImage: const Icon(
                    Icons.flag,
                    size: 16,
                    color: Color(0xFF273951),
                  )),
            if (selectedPoolUrl != null)
              _showOneCoinData("Pool Url", [selectedPoolUrl],
                  CoinDataWizardStep.poolUrlSelect,
                  prefixIconOrImage: const Icon(
                    Icons.public,
                    size: 16,
                    color: Color(0xFF273951),
                  )),
            if (selectedPoolPort != null)
              _showOneCoinData("Pool Port", [selectedPoolPort.toString()],
                  CoinDataWizardStep.portSelect,
                  prefixIconOrImage: const Icon(
                    Icons.onetwothree,
                    size: 16,
                    color: Color(0xFF273951),
                  )),
            if (selectedPoolUrl != null && selectedPoolPort != null) ...[
              _showOneCoinData(
                  "Wallet Address",
                  [
                    walletAddress.isNotEmpty
                        ? walletAddress.length >= 8
                            ? "${walletAddress.substring(walletAddress.length - 8)} (Showing last 8 char)"
                            : walletAddress
                        : "Enter wallet address to start mining"
                  ],
                  CoinDataWizardStep.walletAddressInput,
                  prefixIconOrImage: const Icon(
                    Icons.wallet,
                    size: 16,
                    color: Color(0xFF273951),
                  )),
              _showOneCoinData("Mining Engine", [selectedMinerBinary.name],
                  CoinDataWizardStep.miningEngineSelect,
                  prefixIconOrImage: const Icon(
                    Icons.developer_board,
                    size: 16,
                    color: Color(0xFF273951),
                  ),
                  subContent: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (coinDataProvider.threadCount != null) ...[
                        Text(
                          "Miner Options",
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                        Text(
                          "Thread count: ${coinDataProvider.threadCount.toString()}",
                          style: Theme.of(context).textTheme.labelSmall,
                        )
                      ],
                      if (coinDataProvider.selectedMinerBinary ==
                          MinerBinary.xmrigCC) ...[
                        Text(
                          "Server URL: ${coinDataProvider.xmrigCCServerUrl}",
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                        Text(
                            "Server Token: ${coinDataProvider.xmrigCCServerToken}",
                            style: Theme.of(context).textTheme.labelSmall),
                        if (coinDataProvider.xmrigCCWorkerId != null)
                          Text("Worker Id: ${coinDataProvider.xmrigCCWorkerId}",
                              style: Theme.of(context).textTheme.labelSmall)
                      ],
                    ],
                  )),
            ]
          ],
          if (selectedCoinData == null)
            _showOneCoinData(
              "Select coin to start",
              [""],
              CoinDataWizardStep.coinNameSelect,
              prefixIconOrImage: const Icon(
                Icons.monetization_on,
                size: 16,
                color: Color(0xFF273951),
              ),
            )
        ],
      ),
    );
  }

  Widget _showCoinData(CoinDataProvider coinDataProvider) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Configure Miner",
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          Expanded(
              child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                children: [
                  _showSelectedCoinData(coinDataProvider),
                  if (coinDataProvider.selectedPoolUrl != null &&
                      coinDataProvider.selectedPoolPort != null &&
                      coinDataProvider.walletAddress.isNotEmpty) ...[
                    const SizedBox(
                      height: 8,
                    ),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 8,
                      children: [
                        ElevatedButton(
                          onPressed: _userUploadedConfigSaved
                              ? null
                              : () async {
                                  await _saveMinerConfigInBackend(
                                      minerConfigToJson(
                                          _getMinerConfig(coinDataProvider)),
                                      true);
                                },
                          child: _userUploadedConfigSaved
                              ? Wrap(
                                  spacing: 4,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: const [
                                    Text("Saved"),
                                    Icon(Icons.check)
                                  ],
                                )
                              : _userUploadedConfigSaving
                                  ? Wrap(
                                      spacing: 4,
                                      crossAxisAlignment:
                                          WrapCrossAlignment.center,
                                      children: const [
                                        Text("Saving"),
                                        SizedBox(
                                          width: 10,
                                          height: 10,
                                          child: CircularProgressIndicator(),
                                        )
                                      ],
                                    )
                                  : const Text("Save Config"),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: _userUploadedConfigSaveHasError
                                  ? Theme.of(context).colorScheme.error
                                  : null,
                              foregroundColor: _userUploadedConfigSaveHasError
                                  ? Theme.of(context).colorScheme.onError
                                  : null,
                              shadowColor: Colors.transparent),
                        ),
                        ElevatedButton(
                          onPressed: () async {
                            await _onPressStartMining(coinDataProvider);
                          },
                          child: Wrap(
                            spacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              const Text("Start Mining"),
                              if (_configSaving)
                                const SizedBox(
                                  width: 10,
                                  height: 10,
                                  child: CircularProgressIndicator(),
                                )
                            ],
                          ),
                          style: ElevatedButton.styleFrom(
                              shadowColor: Colors.transparent),
                        ),
                      ],
                    )
                  ],
                  const SizedBox(
                    height: 8,
                  ),
                  Text(
                    "Advanced Options",
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(
                    height: 8,
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 80),
                    child: Divider(
                      height: 0,
                    ),
                  ),
                  const SizedBox(
                    height: 8,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            Provider.of<UiStateProvider>(context, listen: false)
                                .minerConfigPageShowMinerEngineSelect = true;
                            widget.setCurrentWizardStep(
                                WizardStep.usersMinerConfigs);
                          },
                          child: const Text("Saved configs"),
                          style: ElevatedButton.styleFrom(
                              shadowColor: Colors.transparent),
                        ),
                        const SizedBox(
                          height: 8,
                        ),
                        ElevatedButton(
                          onPressed: () {
                            Provider.of<UiStateProvider>(context, listen: false)
                                .minerConfigPageShowMinerEngineSelect = true;
                            widget.setCurrentWizardStep(WizardStep.minerConfig);
                          },
                          child: const Text("Use custom config"),
                          style: ElevatedButton.styleFrom(
                              shadowColor: Colors.transparent),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(
                    height: 16,
                  ),
                  CurrentlyMining(
                      setCurrentWizardStep: widget.setCurrentWizardStep)
                ],
              ),
            ),
          ))
        ],
      ),
    );
  }

  Widget _getCurrentStep() {
    final coinDataProvider = Provider.of<CoinDataProvider>(context);

    switch (_currentCoinDataWizardStep) {
      case CoinDataWizardStep.coinNameSelect:
        return CoinName(
          setCurrentCoinDataWizardStep: _setCurrentCoinDataWizardStep,
        );
      case CoinDataWizardStep.poolNameSelect:
        return PoolName(
          setCurrentCoinDataWizardStep: _setCurrentCoinDataWizardStep,
        );
      case CoinDataWizardStep.regionSelect:
        return Region(
          setCurrentCoinDataWizardStep: _setCurrentCoinDataWizardStep,
        );
      case CoinDataWizardStep.poolUrlSelect:
        return PoolUrl(
          setCurrentCoinDataWizardStep: _setCurrentCoinDataWizardStep,
        );
      case CoinDataWizardStep.portSelect:
        return PoolPort(
          setCurrentCoinDataWizardStep: _setCurrentCoinDataWizardStep,
        );
      case CoinDataWizardStep.walletAddressInput:
        return WalletAddress(
            setCurrentCoinDataWizardStep: _setCurrentCoinDataWizardStep);
      case CoinDataWizardStep.miningEngineSelect:
        return MiningEngine(
            setCurrentCoinDataWizardStep: _setCurrentCoinDataWizardStep);
      case null:
        return _showCoinData(coinDataProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _getCurrentStep();
  }
}
