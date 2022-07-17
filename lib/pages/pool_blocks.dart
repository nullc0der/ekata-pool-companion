import 'package:ekatapoolcompanion/models/poolblock.dart';
import 'package:ekatapoolcompanion/providers/poolblock.dart';
import 'package:ekatapoolcompanion/providers/poolstat.dart';
import 'package:ekatapoolcompanion/services/poolblock.dart';
import 'package:ekatapoolcompanion/utils/common.dart';
import 'package:ekatapoolcompanion/widgets/custom_expansion_tile.dart';
import 'package:ekatapoolcompanion/widgets/info_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:matomo_tracker/matomo_tracker.dart';
import 'package:provider/provider.dart';

class PoolBlocks extends StatefulWidget {
  const PoolBlocks({Key? key}) : super(key: key);

  @override
  State<PoolBlocks> createState() => _PoolBlocksState();
}

class _PoolBlocksState extends State<PoolBlocks> {
  bool _isNewBlocksLoading = false;

  @override
  void initState() {
    super.initState();
    if (MatomoTracker.instance.initialized) {
      MatomoTracker.instance
          .trackEvent(eventCategory: 'Page Change', action: 'Pool Blocks');
    }
  }

  void _onLongPressBlockHash(String text) {
    Clipboard.setData(ClipboardData(text: text)).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Block hash copied to clipboard")));
    });
  }

  void _onPressLoadMore() {
    var poolBlockProvider =
        Provider.of<PoolBlockProvider>(context, listen: false);
    var poolStat =
        Provider.of<PoolStatProvider>(context, listen: false).poolStat;
    setState(() {
      _isNewBlocksLoading = true;
    });
    var newBlocks = PoolBlockService().getPoolBlocks(poolBlockProvider
        .poolBlocks[poolBlockProvider.poolBlocks.length - 1].height);
    newBlocks.then((value) {
      poolBlockProvider.addBlocks(value,
          networkHeight: poolStat?.network.height,
          depth: poolStat?.config.depth,
          slushMiningEnabled: poolStat?.config.slushMiningEnabled,
          blockTime: poolStat?.config.blockTime,
          weight: poolStat?.config.weight);
      setState(() {
        _isNewBlocksLoading = false;
      });
    });
  }

  Widget _poolBlockWidgetExpandedChild(
      BuildContext context,
      String maturity,
      String blockHash,
      int sharesDiff,
      DateTime timeFound,
      String reward,
      int coinUnits) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Maturity"),
              Text(maturity),
            ],
          ),
          Divider(
            color: Theme.of(context).primaryColor,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text("Block hash"),
                flex: 1,
              ),
              Expanded(
                  child: GestureDetector(
                onLongPress: () {
                  return _onLongPressBlockHash(blockHash);
                },
                child: Text(blockHash),
              )),
            ],
          ),
          Divider(
            color: Theme.of(context).primaryColor,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Time found"),
              Text(DateFormat.yMd().add_jm().format(timeFound)),
            ],
          ),
          Divider(
            color: Theme.of(context).primaryColor,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Shares/Diff"),
              Text(
                "$sharesDiff%",
                style: sharesDiff > 0
                    ? const TextStyle(color: Colors.green)
                    : const TextStyle(color: Colors.red),
              ),
            ],
          ),
          Divider(
            color: Theme.of(context).primaryColor,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Reward"),
              Text(getReadableCoins(
                reward,
                coinUnits,
              )),
            ],
          ),
          const SizedBox(
            height: 12,
          )
        ],
      ),
    );
  }

  Widget _poolBlockWidget(
      BuildContext context,
      int blockHeight,
      int difficulty,
      String maturity,
      String blockHash,
      int sharesDiff,
      DateTime timeFound,
      String reward,
      int coinUnits,
      bool initiallyExpanded) {
    return CustomExpansionTile(
      title: Text("Block Height: $blockHeight"),
      trailing: const Text(""),
      subtitle: Text("Difficulty: $difficulty"),
      children: [
        _poolBlockWidgetExpandedChild(context, maturity, blockHash, sharesDiff,
            timeFound, reward, coinUnits)
      ],
      textColor: Theme.of(context).primaryColor,
      collapsedTextColor: Theme.of(context).primaryColor,
      backgroundColor: const Color(0xFFEBF1FD),
      collapsedBackgroundColor: const Color(0xFFEBF1FD),
      initiallyExpanded: initiallyExpanded,
    );
  }

  @override
  Widget build(BuildContext context) {
    var poolBlocks = Provider.of<PoolBlockProvider>(context).poolBlocks;
    var poolStat = Provider.of<PoolStatProvider>(context).poolStat;
    return poolStat != null
        ? ListView(padding: const EdgeInsets.symmetric(vertical: 8), children: [
            getInfoCard(
                poolStat.pool.totalBlocks.toString(), "Total Block Mined"),
            getInfoCard(
                poolStat.config.depth.toString(), "Maturity Depth Requirement"),
            const SizedBox(
              height: 16,
            ),
            ...poolBlocks.asMap().entries.map((e) {
              int id = e.key;
              PoolBlock item = e.value;
              return _poolBlockWidget(
                  context,
                  item.height,
                  item.difficulty,
                  item.maturity,
                  item.hash,
                  item.sharesDiffPercent,
                  item.time,
                  item.reward,
                  poolStat.config.coinUnits,
                  id == 0);
            }),
            const SizedBox(
              height: 16,
            ),
            Center(
              child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      minimumSize: const Size(120, 50)),
                  onPressed: () => _onPressLoadMore(),
                  child: _isNewBlocksLoading
                      ? const CircularProgressIndicator(
                          color: Colors.white,
                        )
                      : const Text("Load More")),
            )
          ])
        : Container(
            width: double.infinity,
            height: double.infinity,
            alignment: Alignment.center,
            child: const CircularProgressIndicator(),
          );
  }
}
