class CCMinerSummary {
  CCMinerSummary(
      {required this.algo,
      required this.currentHash,
      required this.solved,
      required this.accepted,
      required this.rejected,
      required this.diff,
      required this.uptime});

  String algo;
  String currentHash;
  String solved;
  String accepted;
  String rejected;
  String diff;
  String uptime;
}
