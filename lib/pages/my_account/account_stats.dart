import 'dart:async';

import 'package:ekatapoolcompanion/models/addressstat.dart';
import 'package:ekatapoolcompanion/models/poolpayment.dart';
import 'package:ekatapoolcompanion/models/poolstat.dart';
import 'package:ekatapoolcompanion/providers/addressstat.dart';
import 'package:ekatapoolcompanion/providers/addressstatpayments.dart';
import 'package:ekatapoolcompanion/providers/poolstat.dart';
import 'package:ekatapoolcompanion/services/addressstat.dart';
import 'package:ekatapoolcompanion/utils/common.dart';
import 'package:ekatapoolcompanion/utils/constants.dart';
import 'package:ekatapoolcompanion/widgets/payment_widget.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timeago/timeago.dart' as timeago;

class AccountStats extends StatefulWidget {
  const AccountStats({Key? key}) : super(key: key);

  @override
  State<AccountStats> createState() => _AccountStatsState();
}

class _AccountStatsState extends State<AccountStats> {
  final _accountFormKey = GlobalKey<FormState>();
  bool _isNewPaymentsLoading = false;
  String _walletAddress = "";
  Timer? _timer;
  final _minPayoutFieldController = TextEditingController();
  final _walletAddressFieldController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadWalletAddress();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _minPayoutFieldController.dispose();
    _walletAddressFieldController.dispose();
    super.dispose();
  }

  Future<void> _loadWalletAddress() async {
    final prefs = await SharedPreferences.getInstance();
    String walletAddress =
        prefs.getString(Constants.walletAddressKeySharedPrefs) ?? "";

    setState(() {
      _walletAddress = walletAddress;
    });
    if (walletAddress.isNotEmpty) {
      _walletAddressFieldController.text = walletAddress.toString();
      _getAddressPayoutLevel(walletAddress);
      _getAddressStats(walletAddress);
      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 10), (_) {
        _getAddressStats(walletAddress);
      });
    }
  }

  Future<void> _saveWalletAddress(String address) async {
    final prefs = await SharedPreferences.getInstance();
    var addressStatPaymentsProvider =
        Provider.of<AddressStatPaymentsProvider>(context, listen: false);

    if (address != _walletAddress && address.isNotEmpty) {
      setState(() {
        _walletAddress = address;
      });
      prefs.setString(Constants.walletAddressKeySharedPrefs, address);
      _timer?.cancel();
      _getAddressPayoutLevel(address);
      addressStatPaymentsProvider.clearPayments();
      _timer = Timer.periodic(const Duration(seconds: 10), (_) {
        _getAddressStats(address);
      });
      _getAddressStats(address);
    }
  }

  void _getAddressStats(String walletAddress) {
    var addressStatProvider =
        Provider.of<AddressStatProvider>(context, listen: false);
    var newAddressStat = AddressStatService().getAddressStat(walletAddress);
    newAddressStat.then((value) {
      addressStatProvider.addressStat = value;
    });
  }

  void _getAddressPayoutLevel(String walletAddress) {
    AddressStatService()
        .getPayoutLevel(walletAddress)
        .then((value) => _minPayoutFieldController.text = value.toString());
  }

  void _onPressLoadMore() {
    var addressStatPaymentsProvider =
        Provider.of<AddressStatPaymentsProvider>(context, listen: false);
    var addressStatPayments = addressStatPaymentsProvider.addressStatPayments;
    setState(() {
      _isNewPaymentsLoading = true;
    });
    var newPayments = AddressStatService().getAddressPayments(
        _walletAddress,
        addressStatPayments[addressStatPayments.length - 1]
                .timeStamp
                .millisecondsSinceEpoch ~/
            1000);
    newPayments.then((value) {
      addressStatPaymentsProvider.addPayments(value);
      setState(() {
        _isNewPaymentsLoading = false;
      });
    });
  }

  Widget _statRow(IconData icon, String title, String data) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        RichText(
          text: TextSpan(children: [
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Container(
                  padding: const EdgeInsets.only(right: 4.0),
                  child: Icon(
                    icon,
                    color: Theme.of(context).primaryColor,
                    size: 16,
                  )),
            ),
            TextSpan(
                text: title,
                style: TextStyle(color: Theme.of(context).primaryColor))
          ]),
        ),
        Text(
          data,
          style: TextStyle(color: Theme.of(context).primaryColor),
        )
      ],
    );
  }

  List<Widget> _getStatRows(AddressStat addressStat, PoolStat poolStat) {
    return [
      _StatRowItem(
          iconData: Icons.account_balance,
          title: "Pending Balance",
          data: getReadableCoins(
              addressStat.stats.balance, poolStat.config.coinUnits, 'BAZA')),
      _StatRowItem(
          iconData: Icons.payments,
          title: "Total Paid",
          data: getReadableCoins(
              addressStat.stats.paid, poolStat.config.coinUnits, 'BAZA')),
      _StatRowItem(
          iconData: Icons.schedule,
          title: "Last Share Submitted",
          data: timeago.format(DateTime.fromMillisecondsSinceEpoch(
              (int.tryParse(addressStat.stats.lastShare) ?? 0) * 1000))),
      _StatRowItem(
          iconData: Icons.developer_board,
          title: "Hash rate",
          data:
              '${addressStat.stats.hashrate}${addressStat.stats.hashrate != '0' ? '/s' : ''}'),
      _StatRowItem(
          iconData: Icons.cloud_done,
          title: "Total Hashes Submitted",
          data: addressStat.stats.hashes),
    ].map((item) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        child: _statRow(item.iconData, item.title, item.data),
      );
    }).toList();
  }

  Widget _buildAccountForm() {
    return Form(
      key: _accountFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(
            height: 12.0,
          ),
          TextFormField(
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return "Wallet address can't be empty";
                }
                return null;
              },
              controller: _walletAddressFieldController,
              decoration: const InputDecoration(
                  labelText: "Wallet Address",
                  border: OutlineInputBorder(),
                  hintText: "Enter wallet address"),
              onSaved: (address) {
                if (address != null) {
                  _saveWalletAddress(address);
                }
              }),
          const SizedBox(
            height: 16.0,
          ),
          TextFormField(
            validator: (value) {
              if (value == null || value.isEmpty) {
                return "Min payout can't be empty";
              }
              if (double.tryParse(value) == null) {
                return "Make sure to enter numeric value";
              }
              if (double.parse(value) < 0) {
                return "Make sure to enter a value greater than 0";
              }
              return null;
            },
            keyboardType: TextInputType.number,
            controller: _minPayoutFieldController,
            decoration: const InputDecoration(
                labelText: "Min payout level",
                border: OutlineInputBorder(),
                hintText: "Enter min payout level"),
            onSaved: (level) {
              if (level != null) {
                AddressStatService()
                    .setPayoutLevel(_walletAddress, int.parse(level));
              }
            },
          ),
          const SizedBox(
            height: 8.0,
          ),
          ElevatedButton(
              style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(40)),
              onPressed: () {
                if (_accountFormKey.currentState!.validate()) {
                  _accountFormKey.currentState!.save();
                }
              },
              child: const Text("Save")),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    var poolStat = Provider.of<PoolStatProvider>(context).poolStat;
    var addressStat = Provider.of<AddressStatProvider>(context).addressStat;
    var addressStatPayments =
        Provider.of<AddressStatPaymentsProvider>(context).addressStatPayments;

    return addressStat != null && poolStat != null
        ? Expanded(
            child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              Container(
                margin: const EdgeInsets.only(right: 8, left: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "My Account Stats",
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor),
                    ),
                    SizedBox(
                      width: 80,
                      child: Divider(
                        color: Theme.of(context).primaryColor,
                        thickness: 2,
                      ),
                    ),
                    const SizedBox(
                      height: 8,
                    ),
                    ..._getStatRows(addressStat, poolStat),
                    const SizedBox(
                      height: 32.0,
                    ),
                    Text(
                      "Wallet Address and Min Payout",
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor),
                    ),
                    SizedBox(
                      width: 80,
                      child: Divider(
                        color: Theme.of(context).primaryColor,
                        thickness: 2,
                      ),
                    ),
                    const SizedBox(
                      height: 8,
                    ),
                    _buildAccountForm(),
                    const SizedBox(
                      height: 32.0,
                    ),
                    Text(
                      "Payments",
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor),
                    ),
                    SizedBox(
                      width: 80,
                      child: Divider(
                        color: Theme.of(context).primaryColor,
                        thickness: 2,
                      ),
                    ),
                    const SizedBox(
                      height: 8,
                    ),
                    ...addressStatPayments.asMap().entries.map((e) {
                      int id = e.key;
                      PoolPayment payment = e.value;
                      return PaymentWidget(
                        txHash: payment.hash,
                        timeSent: payment.timeStamp,
                        amount: getReadableCoins(payment.amount.toString(),
                            poolStat.config.coinUnits, 'BAZA'),
                        fee: getReadableCoins(payment.fee.toString(),
                            poolStat.config.coinUnits, 'BAZA'),
                        margin: const EdgeInsets.only(top: 8.0),
                        initiallyExpanded: id == 0,
                      );
                    }),
                    const SizedBox(
                      height: 16,
                    ),
                    Center(
                      child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              minimumSize: const Size(120, 50)),
                          onPressed: () => _onPressLoadMore(),
                          child: _isNewPaymentsLoading
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : const Text("Load More")),
                    )
                  ],
                ),
              )
            ],
          ))
        : const Expanded(
            child: Center(
            child: CircularProgressIndicator(),
          ));
  }
}

class _StatRowItem {
  final IconData iconData;
  final String title;
  final String data;

  _StatRowItem(
      {required this.iconData, required this.title, required this.data});
}
