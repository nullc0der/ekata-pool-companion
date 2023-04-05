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
import 'package:ekatapoolcompanion/utils/desktop_miner/miner.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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

  void _setCurrentCoinDataWizardStep(
      CoinDataWizardStep? currentCoinDataWizardStep) {
    setState(() {
      _currentCoinDataWizardStep = currentCoinDataWizardStep;
    });
  }

  Widget _showOneCoinData(
      String label, String content, CoinDataWizardStep coinDataWizardStep,
      {required Widget prefixIconOrImage}) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () {
        _setCurrentCoinDataWizardStep(coinDataWizardStep);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
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
                if (content.isNotEmpty) ...[
                  const SizedBox(
                    height: 2,
                  ),
                  Text(
                    content,
                    style: Theme.of(context).textTheme.labelMedium,
                  )
                ]
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
    final selectedMiningBinary = coinDataProvider.selectedMinerBinary;

    return Card(
      shadowColor: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            if (selectedCoinData != null) ...[
              _showOneCoinData(
                "Coin/Token Name",
                selectedCoinData.coinName,
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
                _showOneCoinData("Pool Name", selectedPool,
                    CoinDataWizardStep.poolNameSelect,
                    prefixIconOrImage: const Icon(
                      Icons.group,
                      size: 16,
                      color: Color(0xFF273951),
                    )),
              if (selectedRegion != null)
                _showOneCoinData("Pool Region", selectedRegion,
                    CoinDataWizardStep.regionSelect,
                    prefixIconOrImage: const Icon(
                      Icons.flag,
                      size: 16,
                      color: Color(0xFF273951),
                    )),
              if (selectedPoolUrl != null)
                _showOneCoinData("Pool Url", selectedPoolUrl,
                    CoinDataWizardStep.poolUrlSelect,
                    prefixIconOrImage: const Icon(
                      Icons.public,
                      size: 16,
                      color: Color(0xFF273951),
                    )),
              if (selectedPoolPort != null)
                _showOneCoinData("Pool Port", selectedPoolPort.toString(),
                    CoinDataWizardStep.portSelect,
                    prefixIconOrImage: const Icon(
                      Icons.onetwothree,
                      size: 16,
                      color: Color(0xFF273951),
                    )),
              if (selectedPoolUrl != null && selectedPoolPort != null) ...[
                _showOneCoinData(
                    "Wallet Address",
                    walletAddress.isNotEmpty
                        ? walletAddress.length >= 8
                            ? "${walletAddress.substring(walletAddress.length - 8)} (Showing last 8 char)"
                            : walletAddress
                        : "Enter wallet address to start mining",
                    CoinDataWizardStep.walletAddressInput,
                    prefixIconOrImage: const Icon(
                      Icons.wallet,
                      size: 16,
                      color: Color(0xFF273951),
                    )),
                _showOneCoinData("Mining Engine", selectedMiningBinary.name,
                    CoinDataWizardStep.miningEngineSelect,
                    prefixIconOrImage: const Icon(
                      Icons.developer_board,
                      size: 16,
                      color: Color(0xFF273951),
                    ))
              ]
            ],
            if (selectedCoinData == null)
              _showOneCoinData(
                "Select coin to start",
                "",
                CoinDataWizardStep.coinNameSelect,
                prefixIconOrImage: const Icon(
                  Icons.monetization_on,
                  size: 16,
                  color: Color(0xFF273951),
                ),
              )
          ],
        ),
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
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "URL to be used for mining: ${coinDataProvider.selectedPoolUrl}:${coinDataProvider.selectedPoolPort}",
                            style: Theme.of(context).textTheme.labelMedium,
                          ),
                          if (coinDataProvider.threadCount != null)
                            Text(
                              "Thread count: ${coinDataProvider.threadCount.toString()}",
                              style: Theme.of(context).textTheme.labelMedium,
                            ),
                          if (coinDataProvider.selectedMinerBinary ==
                              MinerBinary.xmrigCC) ...[
                            const SizedBox(
                              height: 8,
                            ),
                            Text(
                              "XmrigCC Options",
                              style: Theme.of(context).textTheme.labelLarge,
                            ),
                            Text(
                              "Server URL: ${coinDataProvider.xmrigCCServerUrl}",
                              style: Theme.of(context).textTheme.labelMedium,
                            ),
                            Text(
                                "Server Token: ${coinDataProvider.xmrigCCServerToken}",
                                style: Theme.of(context).textTheme.labelMedium),
                            if (coinDataProvider.xmrigCCWorkerId != null)
                              Text(
                                  "Worker Id: ${coinDataProvider.xmrigCCWorkerId}",
                                  style:
                                      Theme.of(context).textTheme.labelMedium)
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(
                      height: 8,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: ElevatedButton(
                        onPressed: () {
                          String? gpuVendor = Provider.of<MinerStatusProvider>(
                                  context,
                                  listen: false)
                              .gpuVendor;
                          bool deviceHasGPU = gpuVendor != null;
                          CoinData? selectedCoinData =
                              coinDataProvider.selectedCoinData;
                          if (selectedCoinData != null) {
                            Provider.of<MinerStatusProvider>(context,
                                    listen: false)
                                .coinData = selectedCoinData;
                            MinerConfig minerConfig = MinerConfig(pools: [
                              Pool(
                                  algo: selectedCoinData.coinAlgo,
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
                            Provider.of<MinerStatusProvider>(context,
                                    listen: false)
                                .minerConfig = minerConfig;
                            if (coinDataProvider.threadCount != null) {
                              Provider.of<MinerStatusProvider>(context,
                                      listen: false)
                                  .threadCount = coinDataProvider.threadCount;
                            }
                            Provider.of<MinerStatusProvider>(context,
                                        listen: false)
                                    .selectedMinerBinary =
                                coinDataProvider.selectedMinerBinary;
                            if (coinDataProvider.selectedMinerBinary ==
                                MinerBinary.xmrigCC) {
                              Provider.of<MinerStatusProvider>(context,
                                          listen: false)
                                      .xmrigCCServerUrl =
                                  coinDataProvider.xmrigCCServerUrl;
                              Provider.of<MinerStatusProvider>(context,
                                          listen: false)
                                      .xmrigCCServerToken =
                                  coinDataProvider.xmrigCCServerToken;
                              Provider.of<MinerStatusProvider>(context,
                                          listen: false)
                                      .xmrigCCWorkerId =
                                  coinDataProvider.xmrigCCWorkerId;
                            }
                            Provider.of<UiStateProvider>(context, listen: false)
                                .minerConfigPageShowMinerEngineSelect = false;
                            widget.setCurrentWizardStep(WizardStep.minerConfig);
                          }
                        },
                        child: const Text("Review final config"),
                        style: ElevatedButton.styleFrom(
                            minimumSize: const Size.fromHeight(35),
                            shadowColor: Colors.transparent),
                      ),
                    ),
                  ],
                  const SizedBox(
                    height: 24,
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
