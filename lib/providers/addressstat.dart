import 'package:ekatapoolcompanion/models/addressstat.dart';
import 'package:flutter/material.dart';

class AddressStatProvider extends ChangeNotifier {
  AddressStat? _addressStat;

  AddressStat? get addressStat => _addressStat;

  set addressStat(AddressStat? newAddressStat) {
    _addressStat = newAddressStat;
    notifyListeners();
  }
}
