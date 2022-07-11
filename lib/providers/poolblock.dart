import 'dart:collection';

import 'package:ekatapoolcompanion/models/poolblock.dart';
import 'package:flutter/material.dart';

class PoolBlockProvider extends ChangeNotifier {
  final List<PoolBlock> _poolBlocks = [];

  UnmodifiableListView<PoolBlock> get poolBlocks =>
      UnmodifiableListView(_poolBlocks);

  void addBlocks(List<String>? blocks,
      {int? depth,
      int? networkHeight,
      bool? slushMiningEnabled,
      int? blockTime,
      int? weight}) {
    if (blocks != null) {
      for (int i = 0; i < blocks.length; i += 2) {
        PoolBlock _poolBlock = PoolBlock.fromBlockString(
            block: blocks[i],
            height: int.parse(blocks[i + 1]),
            depth: depth ?? 0,
            networkHeight: networkHeight ?? 0,
            slushMiningEnabled: slushMiningEnabled ?? false,
            blockTime: blockTime ?? 0,
            weight: weight ?? 0);
        bool alreadyExist = _poolBlocks
            .where((element) => element.height == _poolBlock.height)
            .isNotEmpty;
        if (!alreadyExist) _poolBlocks.add(_poolBlock);
      }
      _poolBlocks.sort();
      notifyListeners();
    }
  }
}
