import 'dart:async';

import 'package:ekatapoolcompanion/models/coindata.dart';
import 'package:ekatapoolcompanion/pages/miner/coindata/coindatawidget.dart';
import 'package:ekatapoolcompanion/providers/coindata.dart';
import 'package:ekatapoolcompanion/providers/minerstatus.dart';
import 'package:ekatapoolcompanion/services/coindata.dart';
import 'package:ekatapoolcompanion/utils/desktop_miner/miner.dart';
import 'package:ekatapoolcompanion/utils/walletaddress.dart';
import 'package:flutter/material.dart';
import 'package:fluttericon/font_awesome5_icons.dart';
import 'package:provider/provider.dart';

class CoinName extends StatefulWidget {
  const CoinName({Key? key, required this.setCurrentCoinDataWizardStep})
      : super(key: key);

  final ValueChanged<CoinDataWizardStep?> setCurrentCoinDataWizardStep;

  @override
  State<CoinName> createState() => _CoinNameState();
}

class _CoinNameState extends State<CoinName> {
  bool _coinDataFetching = false;
  bool _hasCoinDataFetchError = false;
  int _pageNumber = 0;
  String _searchQueryString = "";
  String _alphaSort = "asc";
  final bool _newestFirst = true;
  Timer? _searchDebounce;
  int _lastCoinDataCount = 0;
  bool _hasReachedBottom = false;

  @override
  void initState() {
    super.initState();
    _fetchCoinDatas();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }

  Future<void> _fetchCoinDatas({bool appendData = false}) async {
    String? gpuVendor =
        Provider.of<MinerStatusProvider>(context, listen: false).gpuVendor;
    try {
      setState(() {
        _coinDataFetching = true;
        _hasCoinDataFetchError = false;
      });
      final coinDatas = await CoinDataService.getCoinDatas(
          pageNumber: _pageNumber,
          perPage: 10,
          alphaSort: _alphaSort,
          newestFirst: _newestFirst,
          searchQuery: _searchQueryString,
          cpuMineable: gpuVendor == null);
      if (appendData) {
        Provider.of<CoinDataProvider>(context, listen: false)
            .addCoinDatas(coinDatas);
      } else {
        Provider.of<CoinDataProvider>(context, listen: false).coinDatas =
            coinDatas;
      }
      final coinDataCount =
          Provider.of<CoinDataProvider>(context, listen: false)
              .coinDatas
              .length;
      setState(() {
        _coinDataFetching = false;
        _hasCoinDataFetchError = false;
        _hasReachedBottom = _lastCoinDataCount == coinDataCount;
        _lastCoinDataCount = coinDataCount;
      });
    } on Exception {
      setState(() {
        _coinDataFetching = false;
        _hasCoinDataFetchError = true;
      });
    }
  }

  void _resetCoinDataAndCount() {
    Provider.of<CoinDataProvider>(context, listen: false).coinDatas = [];
    setState(() {
      _hasReachedBottom = false;
      _lastCoinDataCount = 0;
    });
  }

  Future<void> _onPressDone(CoinData coinData) async {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        duration: Duration(seconds: 1),
        content:
            Text("Done pressed, first item from next steps will be selected")));
    final poolName = Set<String>.from(coinData.pools.map((e) => e.poolName))
        .first
        .trim()
        .toLowerCase();
    final poolRegion = Set<Pool>.from(coinData.pools
        .where((e) => e.poolName.trim().toLowerCase() == poolName)).first;
    final poolUrl = coinData.pools
        .firstWhere((element) =>
            element.poolName.toLowerCase().trim() == poolName &&
            element.region == poolRegion.region)
        .urls
        .first;
    final poolPort = coinData.pools
        .firstWhere((element) =>
            element.poolName.toLowerCase().trim() == poolName &&
            element.region == poolRegion.region)
        .ports
        .first;
    final poolCredentials = await getPoolCredentials("$poolUrl:$poolPort");
    Provider.of<CoinDataProvider>(context, listen: false).selectedCoinData =
        coinData;
    Provider.of<CoinDataProvider>(context, listen: false).selectedPoolName =
        poolName;
    Provider.of<CoinDataProvider>(context, listen: false).selectedRegion =
        poolRegion.region;
    Provider.of<CoinDataProvider>(context, listen: false).selectedPoolUrl =
        poolUrl;
    Provider.of<CoinDataProvider>(context, listen: false).selectedPoolPort =
        poolPort;
    Provider.of<CoinDataProvider>(context, listen: false).walletAddress =
        poolCredentials["walletAddress"] ?? "";
    Provider.of<CoinDataProvider>(context, listen: false).password =
        poolCredentials["password"];
    Provider.of<CoinDataProvider>(context, listen: false).rigId =
        poolCredentials["rigId"];
    Provider.of<CoinDataProvider>(context, listen: false).selectedMinerBinary =
        MinerBinary.xmrig;
    Provider.of<CoinDataProvider>(context, listen: false).threadCount = null;
    widget.setCurrentCoinDataWizardStep(null);
  }

  Widget _renderOneCoinName(CoinData coinData, CoinData? selectedCoinData) {
    return ListTile(
      selected: coinData.coinName == selectedCoinData?.coinName,
      contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      onTap: () {
        Provider.of<CoinDataProvider>(context, listen: false).selectedCoinData =
            coinData;
        widget.setCurrentCoinDataWizardStep(CoinDataWizardStep.poolNameSelect);
      },
      title: Text(
        coinData.coinName,
      ),
      subtitle: Text(
        coinData.coinAlgo,
      ),
      horizontalTitleGap: 0,
      leading: ClipOval(
        child: SizedBox.fromSize(
            size: const Size.fromRadius(12),
            child: Image.network(
              coinData.coinLogoUrl,
              width: 24,
              height: 24,
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.close_rounded),
            )),
      ),
    );
  }

  Widget _showSearchAndSort() {
    return Stack(
      children: [
        Positioned(
            child: TextField(
          decoration:
              const InputDecoration(labelText: "Search by coin name or algo"),
          onChanged: (value) {
            if (_searchDebounce?.isActive ?? false) _searchDebounce?.cancel();
            _searchDebounce = Timer(const Duration(milliseconds: 500), () {
              if (value.length >= 3 || value.isEmpty) {
                setState(() {
                  _searchQueryString = value;
                });
                _resetCoinDataAndCount();
                _fetchCoinDatas();
              }
            });
          },
        )),
        Positioned(
            right: 10,
            top: 20,
            // On multi item add a row, and add spacing with SizedBox
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _alphaSort = _alphaSort == "asc" ? "desc" : "asc";
                });
                _resetCoinDataAndCount();
                _fetchCoinDatas();
              },
              child: Icon(
                _alphaSort == "asc"
                    ? FontAwesome5.sort_alpha_down
                    : FontAwesome5.sort_alpha_down_alt,
                size: 18,
                color: Theme.of(context).primaryColor.withOpacity(0.56),
              ),
            )),
        // Positioned(
        //     right: 30,
        //     top: 15,
        //     child: GestureDetector(
        //       onTap: () {
        //         setState(() {
        //           _newestFirst = !_newestFirst;
        //         });
        //         _fetchCoinDatas();
        //       },
        //       child: Icon(
        //         _newestFirst
        //             ? FontAwesome5.sort_numeric_down_alt
        //             : FontAwesome5.sort_numeric_down,
        //         size: 18,
        //         color: Theme.of(context).primaryColor.withOpacity(0.56),
        //       ),
        //     ))
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final coinDataProvider = Provider.of<CoinDataProvider>(context);
    final coinDatas = coinDataProvider.coinDatas;
    final selectedCoinData = coinDataProvider.selectedCoinData;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Select coin",
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(
            height: 8,
          ),
          _showSearchAndSort(),
          const SizedBox(
            height: 8,
          ),
          Expanded(
              child: coinDatas.isNotEmpty
                  ? NotificationListener<ScrollEndNotification>(
                      onNotification: (scrollEnd) {
                        // TODO: This called twice when list scroll reaches end,
                        // however there should be better method, for now it is
                        // prevented by checking whether the data is fetching from
                        // network or not, research for better method when time
                        if (scrollEnd.metrics.pixels ==
                            scrollEnd.metrics.maxScrollExtent) {
                          if (!_coinDataFetching && !_hasReachedBottom) {
                            setState(() {
                              _pageNumber = _pageNumber + 1;
                            });
                            _fetchCoinDatas(appendData: true);
                          }
                        }
                        return true;
                      },
                      child: ListView(
                        padding: const EdgeInsets.only(bottom: 16),
                        children: [
                          ...coinDatas.map(
                              (e) => _renderOneCoinName(e, selectedCoinData)),
                          if (_coinDataFetching)
                            Container(
                              alignment: Alignment.center,
                              child: const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(),
                              ),
                            )
                        ],
                      ))
                  : Container(
                      alignment: Alignment.center,
                      child: _coinDataFetching
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(),
                            )
                          : _hasCoinDataFetchError
                              ? Text("There is some issue fetching coin data",
                                  style: Theme.of(context).textTheme.labelLarge)
                              : Text("There is no coin to load at this moment",
                                  style:
                                      Theme.of(context).textTheme.labelLarge),
                    )),
          Row(
            mainAxisAlignment: coinDatas.isNotEmpty
                ? MainAxisAlignment.spaceBetween
                : MainAxisAlignment.center,
            children: [
              ElevatedButton(
                  onPressed: () {
                    Provider.of<CoinDataProvider>(context, listen: false)
                        .selectedCoinData = null;
                    Provider.of<CoinDataProvider>(context, listen: false)
                        .selectedPoolUrl = null;
                    Provider.of<CoinDataProvider>(context, listen: false)
                        .selectedPoolPort = null;
                    widget.setCurrentCoinDataWizardStep(null);
                  },
                  style: ElevatedButton.styleFrom(
                      shape: const StadiumBorder(),
                      shadowColor: Colors.transparent),
                  child: const Icon(
                    Icons.arrow_back,
                    size: 16,
                  )),
              if (coinDatas.isNotEmpty)
                Wrap(
                  spacing: 4,
                  children: [
                    ElevatedButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                              duration: Duration(seconds: 1),
                              content: Text(
                                  "Next pressed, first item on list will be selected")));
                          Provider.of<CoinDataProvider>(context, listen: false)
                              .selectedCoinData = coinDatas.first;
                          widget.setCurrentCoinDataWizardStep(
                              CoinDataWizardStep.poolNameSelect);
                        },
                        style: ElevatedButton.styleFrom(
                            shape: const StadiumBorder(),
                            shadowColor: Colors.transparent),
                        child: const Icon(
                          Icons.arrow_forward,
                          size: 16,
                        )),
                    ElevatedButton(
                        onPressed: () async {
                          await _onPressDone(coinDatas.first);
                        },
                        style: ElevatedButton.styleFrom(
                            shape: const StadiumBorder(),
                            shadowColor: Colors.transparent),
                        child: const Icon(
                          Icons.check,
                          size: 16,
                        ))
                  ],
                )
            ],
          )
        ],
      ),
    );
  }
}
