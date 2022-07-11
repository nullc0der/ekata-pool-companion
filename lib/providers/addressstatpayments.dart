import 'dart:collection';

import 'package:ekatapoolcompanion/models/poolpayment.dart';
import 'package:flutter/material.dart';

class AddressStatPaymentsProvider extends ChangeNotifier {
  final List<PoolPayment> _addressStatPayments = [];

  UnmodifiableListView<PoolPayment> get addressStatPayments =>
      UnmodifiableListView(_addressStatPayments);

  void addPayments(List<String>? payments) {
    if (payments != null) {
      for (int i = 0; i < payments.length; i += 2) {
        PoolPayment _payment = PoolPayment.fromPaymentString(
            paymentString: payments[i],
            timeStamp: int.tryParse(payments[i + 1]) ?? 0);
        bool alreadyExist = _addressStatPayments
            .where((element) => element.hash == _payment.hash)
            .isNotEmpty;
        if (!alreadyExist) _addressStatPayments.add(_payment);
      }
      _addressStatPayments.sort();
      notifyListeners();
    }
  }

  void clearPayments() {
    _addressStatPayments.clear();
  }
}
