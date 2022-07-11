import 'package:ekatapoolcompanion/providers/poolstat.dart';
import 'package:ekatapoolcompanion/utils/common.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

typedef OnTapPoolSelectWidgetItem = void Function();

class PoolSelectActionSheet extends StatelessWidget {
  const PoolSelectActionSheet({Key? key}) : super(key: key);

  // TODO: Need to change this to adapt multi pool architecture
  List<Widget> _getPoolSelectWidgets(
      BuildContext context, String networkSpeed, String poolSpeed) {
    const comingSoonSnackBar =
        SnackBar(content: Text("Monero pool support coming soon"));

    return [
      _PoolSelectWidgetItem(
          poolLogoPath: 'assets/images/baza.png',
          poolName: 'Baza',
          networkSpeed: networkSpeed,
          poolSpeed: poolSpeed,
          onTapPoolSelectWidgetItem: () => Navigator.pop(context)),
      _PoolSelectWidgetItem(
          poolLogoPath: 'assets/images/monero.png',
          poolName: 'Monero',
          networkSpeed: '60.0 KH/s',
          poolSpeed: '12.0 KH/s',
          onTapPoolSelectWidgetItem: () {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(comingSoonSnackBar);
          })
    ].map((item) {
      return _PoolSelectWidget(
        poolLogoPath: item.poolLogoPath,
        poolName: item.poolName,
        networkSpeed: item.networkSpeed,
        poolSpeed: item.poolSpeed,
        onTapPoolSelectWidgetItem: item.onTapPoolSelectWidgetItem,
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    var poolStat = Provider.of<PoolStatProvider>(context).poolStat;
    return Container(
        height: 200,
        //margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.all(10),
        alignment: Alignment.center,
        decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
                topRight: Radius.circular(10), topLeft: Radius.circular(10))),
        child: poolStat != null
            ? Column(
                children: [
                  Text("Select Pool",
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Theme.of(context).primaryColor)),
                  SizedBox(
                    width: 80,
                    child: Divider(
                      color: Theme.of(context).primaryColor,
                      thickness: 2,
                    ),
                  ),
                  ..._getPoolSelectWidgets(
                      context,
                      getReadableHashrateString(poolStat.network.difficulty /
                          poolStat.config.coinDifficultyTarget),
                      getReadableHashrateString(
                          poolStat.pool.hashrate.toDouble()))
                ],
              )
            : Container(
                width: double.infinity,
                height: double.infinity,
                alignment: Alignment.center,
                child: const CircularProgressIndicator(),
              ));
  }
}

class _PoolSelectWidget extends StatelessWidget {
  const _PoolSelectWidget(
      {Key? key,
      required this.poolLogoPath,
      required this.poolName,
      required this.networkSpeed,
      required this.poolSpeed,
      required this.onTapPoolSelectWidgetItem})
      : super(key: key);

  final String poolLogoPath;
  final String poolName;
  final String networkSpeed;
  final String poolSpeed;
  final OnTapPoolSelectWidgetItem onTapPoolSelectWidgetItem;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTapPoolSelectWidgetItem,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        margin: const EdgeInsets.only(bottom: 6),
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).primaryColor),
          borderRadius: BorderRadius.circular(5),
        ),
        child: Row(
          children: [
            Image(
              image: AssetImage(poolLogoPath),
              width: 24,
              height: 24,
            ),
            const SizedBox(
              width: 10,
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(poolName,
                    style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w500)),
                Row(
                  children: [
                    Text("Network Speed: $networkSpeed",
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontSize: 10,
                        )),
                    const SizedBox(
                      width: 10,
                    ),
                    Text("Pool Speed: $poolSpeed",
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontSize: 10,
                        )),
                  ],
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}

class _PoolSelectWidgetItem {
  _PoolSelectWidgetItem(
      {required this.poolLogoPath,
      required this.poolName,
      required this.networkSpeed,
      required this.poolSpeed,
      required this.onTapPoolSelectWidgetItem});

  final String poolLogoPath;
  final String poolName;
  final String networkSpeed;
  final String poolSpeed;
  final OnTapPoolSelectWidgetItem onTapPoolSelectWidgetItem;
}
