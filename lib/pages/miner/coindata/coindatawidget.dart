import 'package:ekatapoolcompanion/models/coindata.dart' show CoinData;
import 'package:ekatapoolcompanion/models/minerconfig.dart';
import 'package:ekatapoolcompanion/pages/miner/coindata/coinname.dart';
import 'package:ekatapoolcompanion/pages/miner/coindata/poolname.dart';
import 'package:ekatapoolcompanion/pages/miner/coindata/poolport.dart';
import 'package:ekatapoolcompanion/pages/miner/coindata/poolurl.dart';
import 'package:ekatapoolcompanion/pages/miner/coindata/region.dart';
import 'package:ekatapoolcompanion/pages/miner/currentlymining.dart';
import 'package:ekatapoolcompanion/pages/miner/miner.dart';
import 'package:ekatapoolcompanion/providers/coindata.dart';
import 'package:ekatapoolcompanion/providers/minerstatus.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

enum CoinDataWizardStep {
  coinNameSelect,
  poolNameSelect,
  regionSelect,
  poolUrlSelect,
  portSelect
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

  Widget _showOneCoinData(String label, CoinDataWizardStep coinDataWizardStep,
      {Image? image, Icon? icon}) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        _setCurrentCoinDataWizardStep(coinDataWizardStep);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            image ?? icon!,
            const SizedBox(
              width: 8,
            ),
            Text(
              label,
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const Spacer(),
            const Icon(
              Icons.arrow_circle_right_rounded,
              size: 18,
              color: Color(0xFF273951),
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

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          children: [
            if (selectedCoinData != null) ...[
              _showOneCoinData(
                selectedCoinData.coinName,
                CoinDataWizardStep.coinNameSelect,
                image: Image.network(
                  selectedCoinData.coinLogoUrl,
                  width: 24,
                  height: 24,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.close_rounded,
                    color: Color(0xFF273951),
                  ),
                ),
              ),
              if (selectedPool != null)
                _showOneCoinData(
                    selectedPool, CoinDataWizardStep.poolNameSelect,
                    icon: const Icon(
                      Icons.group,
                      size: 24,
                      color: Color(0xFF273951),
                    )),
              if (selectedRegion != null)
                _showOneCoinData(
                    selectedRegion, CoinDataWizardStep.regionSelect,
                    icon: const Icon(
                      Icons.flag,
                      size: 24,
                      color: Color(0xFF273951),
                    )),
              if (selectedPoolUrl != null)
                _showOneCoinData(
                    selectedPoolUrl, CoinDataWizardStep.poolUrlSelect,
                    icon: const Icon(
                      Icons.public,
                      size: 24,
                      color: Color(0xFF273951),
                    )),
              if (selectedPoolPort != null)
                _showOneCoinData(
                    selectedPoolPort.toString(), CoinDataWizardStep.portSelect,
                    icon: const Icon(
                      Icons.onetwothree,
                      size: 24,
                      color: Color(0xFF273951),
                    )),
            ],
            if (selectedCoinData == null)
              _showOneCoinData(
                  "Select coin to start", CoinDataWizardStep.coinNameSelect,
                  icon: const Icon(
                    Icons.monetization_on,
                    color: Color(0xFF273951),
                  ))
          ],
        ),
      ),
    );
  }

  Widget _showCoinData(CoinDataProvider coinDataProvider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _showSelectedCoinData(coinDataProvider),
          if (coinDataProvider.selectedPoolUrl != null &&
              coinDataProvider.selectedPoolPort != null) ...[
            const SizedBox(
              height: 8,
            ),
            Text(
              "URL to be used for mining: ${coinDataProvider.selectedPoolUrl}:${coinDataProvider.selectedPoolPort}",
              style: Theme.of(context).textTheme.labelMedium,
            ),
            const SizedBox(
              height: 8,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ElevatedButton(
                onPressed: () {
                  String? gpuVendor =
                      Provider.of<MinerStatusProvider>(context, listen: false)
                          .gpuVendor;
                  bool deviceHasGPU = gpuVendor != null;
                  CoinData? selectedCoinData =
                      coinDataProvider.selectedCoinData;
                  if (selectedCoinData != null) {
                    Provider.of<MinerStatusProvider>(context, listen: false)
                        .coinData = selectedCoinData;
                    MinerConfig minerConfig = MinerConfig(pools: [
                      Pool(
                          algo: selectedCoinData.coinAlgo,
                          url:
                              "${coinDataProvider.selectedPoolUrl}:${coinDataProvider.selectedPoolPort}",
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
                    widget.setCurrentWizardStep(WizardStep.walletAddressInput);
                  }
                },
                child: const Text("Proceed"),
                style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(35)),
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
                OutlinedButton(
                    onPressed: () {
                      widget.setCurrentWizardStep(WizardStep.usersMinerConfigs);
                    },
                    child: const Text("Saved configs")),
                const SizedBox(
                  height: 8,
                ),
                OutlinedButton(
                    onPressed: () {
                      widget.setCurrentWizardStep(WizardStep.minerConfig);
                    },
                    child: const Text("Use custom config")),
              ],
            ),
          ),
          const SizedBox(
            height: 16,
          ),
          CurrentlyMining(setCurrentWizardStep: widget.setCurrentWizardStep)
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
      case null:
        return _showCoinData(coinDataProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _getCurrentStep();
  }
}