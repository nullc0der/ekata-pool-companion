class PoolPayment implements Comparable<PoolPayment> {
  PoolPayment(
      {required this.hash,
      required this.amount,
      required this.fee,
      required this.mixin,
      required this.timeStamp});

  final String hash;
  final int amount;
  final int fee;
  final int mixin;
  final DateTime timeStamp;

  factory PoolPayment.fromPaymentString(
      {required String paymentString, required int timeStamp}) {
    List<String> chunks = paymentString.split(':');
    return PoolPayment(
        hash: chunks[0],
        amount: int.tryParse(chunks[1]) ?? 0,
        fee: int.tryParse(chunks[2]) ?? 0,
        mixin: chunks.length > 3 ? int.tryParse(chunks[3]) ?? 0 : 0,
        timeStamp: DateTime.fromMillisecondsSinceEpoch(timeStamp * 1000));
  }

  @override
  int compareTo(PoolPayment other) {
    if (timeStamp.isBefore(other.timeStamp)) {
      return 1;
    } else if (timeStamp.isAfter(other.timeStamp)) {
      return -1;
    } else {
      return 0;
    }
  }
}
