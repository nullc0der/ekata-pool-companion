import 'dart:async';

import 'package:ekatapoolcompanion/models/coindata.dart';
import 'package:ekatapoolcompanion/pages/miner/coindata/coindatawidget.dart';
import 'package:ekatapoolcompanion/providers/coindata.dart';
import 'package:ekatapoolcompanion/providers/minerstatus.dart';
import 'package:ekatapoolcompanion/services/coindata.dart';
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

  Widget _renderOneCoinName(CoinData coinData, CoinData? selectedCoinData) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
          color: selectedCoinData != null &&
                  coinData.coinName == selectedCoinData.coinName
              ? Theme.of(context).primaryColor.withOpacity(0.56)
              : Colors.white,
          borderRadius: BorderRadius.circular(4)),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          Provider.of<CoinDataProvider>(context, listen: false)
              .selectedCoinData = coinData;
          widget
              .setCurrentCoinDataWizardStep(CoinDataWizardStep.poolNameSelect);
        },
        child: Row(
          children: [
            ClipOval(
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
            const SizedBox(
              width: 8,
            ),
            Text(
              coinData.coinName,
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const Spacer(),
            Text(
              coinData.coinAlgo,
              style: Theme.of(context).textTheme.bodySmall,
            )
          ],
        ),
      ),
    );
  }

  Widget _showSearchAndSort() {
    return Stack(
      children: [
        Positioned(
            child: TextField(
          decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: "Search by coin name or algo"),
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
            right: 5,
            top: 15,
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
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Select coin",
            style: Theme.of(context).textTheme.headlineMedium,
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                  style: ElevatedButton.styleFrom(shape: const StadiumBorder()),
                  child: const Icon(
                    Icons.arrow_back,
                    size: 16,
                  )),
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
                  style: ElevatedButton.styleFrom(shape: const StadiumBorder()),
                  child: const Icon(
                    Icons.arrow_forward,
                    size: 16,
                  ))
            ],
          )
        ],
      ),
    );
  }
}
