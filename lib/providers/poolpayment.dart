import 'dart:collection';

import 'package:ekatapoolcompanion/models/poolpayment.dart';
import 'package:flutter/material.dart';

class PoolPaymentProvider extends ChangeNotifier {
  final List<PoolPayment> _poolPayments = [];

  UnmodifiableListView<PoolPayment> get poolPayments =>
      UnmodifiableListView(_poolPayments);

  void addPayments(List<String>? payments) {
    if (payments != null) {
      for (int i = 0; i < payments.length; i += 2) {
        PoolPayment _payment = PoolPayment.fromPaymentString(
            paymentString: payments[i],
            timeStamp: int.tryParse(payments[i + 1]) ?? 0);
        bool alreadyExist = _poolPayments
            .where((element) => element.hash == _payment.hash)
            .isNotEmpty;
        if (!alreadyExist) _poolPayments.add(_payment);
      }
      _poolPayments.sort();
      notifyListeners();
    }
  }
}
