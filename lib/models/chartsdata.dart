class ChartData {
  ChartData({
    required this.time,
    required this.value,
  });

  final DateTime time;
  final int value;

  factory ChartData.fromList(List<int> hashrate) {
    return ChartData(
        time: DateTime.fromMillisecondsSinceEpoch(hashrate[0] * 1000),
        value: hashrate[1]);
  }
}
