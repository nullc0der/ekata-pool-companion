import 'dart:io';

import 'package:flutter/material.dart';

class MinerSupport extends StatelessWidget {
  const MinerSupport({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text("Miner support for ${Platform.operatingSystem} coming soon"),
    );
  }
}
