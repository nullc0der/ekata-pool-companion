import 'package:ekatapoolcompanion/models/addressstat.dart';
import 'package:flutter/material.dart';

class AddressStatProvider extends ChangeNotifier {
  AddressStat? _addressStat;
  bool _hasFetchError = false;

  AddressStat? get addressStat => _addressStat;
  bool get hasFetchError => _hasFetchError;

  set addressStat(AddressStat? newAddressStat) {
    _addressStat = newAddressStat;
    notifyListeners();
  }

  set hasFetchError(bool newHasFetchError) {
    _hasFetchError = newHasFetchError;
    notifyListeners();
  }
}
