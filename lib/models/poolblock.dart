import 'package:ekatapoolcompanion/utils/common.dart';

class PoolBlock implements Comparable<PoolBlock> {
  PoolBlock(
      {required this.height,
      required this.hash,
      required this.time,
      required this.difficulty,
      required this.shares,
      required this.orphaned,
      required this.reward,
      required this.maturity,
      required this.status,
      required this.sharesDiffPercent});
  final int height;
  final String hash;
  final DateTime time;
  final int difficulty;
  final int shares;
  final String orphaned;
  final String reward;
  final String maturity;
  final String status;
  final int sharesDiffPercent;

  factory PoolBlock.fromBlockString(
      {required String block,
      required int height,
      required int depth,
      required int networkHeight,
      required bool slushMiningEnabled,
      required int blockTime,
      required int weight}) {
    List<String> chunks = block.split(':');
    String status = 'pending';
    if (chunks.length >= 6) {
      switch (chunks[4]) {
        case '0':
          status = 'unlocked';
          break;
        case '1':
          status = 'orphaned';
          break;
      }
    }
    int toGo = depth - (networkHeight - height);

    return PoolBlock(
        height: height,
        hash: chunks[0],
        time: DateTime.fromMillisecondsSinceEpoch(int.parse(chunks[1]) * 1000),
        difficulty: int.parse(chunks[2]),
        shares: int.parse(chunks[3]),
        orphaned: chunks.length >= 6 ? chunks[4] : '2',
        reward: chunks.length >= 6 ? chunks[5] : '0',
        maturity: toGo < 1 ? '' : '$toGo to go',
        status: status,
        sharesDiffPercent: calculateSharesDiffPercent(int.parse(chunks[2]),
            int.parse(chunks[3]), slushMiningEnabled, blockTime, weight));
  }

  @override
  int compareTo(PoolBlock otherPoolBlock) {
    if (height < otherPoolBlock.height) {
      return 1;
    } else if (height > otherPoolBlock.height) {
      return -1;
    } else {
      return 0;
    }
  }
}
