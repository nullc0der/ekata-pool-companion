import 'dart:async';
import 'dart:io';

import 'package:ekatapoolcompanion/pages/my_account/account_stats.dart';
import 'package:ekatapoolcompanion/pages/my_account/miner.dart';
import 'package:ekatapoolcompanion/pages/my_account/miner_support.dart';
import 'package:ekatapoolcompanion/utils/constants.dart';
import 'package:ekatapoolcompanion/widgets/tabs.dart';
import 'package:flutter/material.dart';
import 'package:matomo_tracker/matomo_tracker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MyAccount extends StatefulWidget {
  const MyAccount({Key? key}) : super(key: key);

  @override
  State<MyAccount> createState() => _MyAccountState();
}

class _MyAccountState extends State<MyAccount> {
  String _walletAddress = "";
  final _walletAddressFormKey = GlobalKey<FormState>();
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadWalletAddress();
    if (MatomoTracker.instance.initialized) {
      MatomoTracker.instance
          .trackEvent(eventCategory: 'Page Change', action: 'My Account');
    }
  }

  Future<void> _loadWalletAddress() async {
    final prefs = await SharedPreferences.getInstance();
    String walletAddress =
        prefs.getString(Constants.walletAddressKeySharedPrefs) ?? "";

    setState(() {
      _walletAddress = walletAddress;
    });
  }

  Future<void> _saveWalletAddress(String address) async {
    final prefs = await SharedPreferences.getInstance();

    if (address != _walletAddress && address.isNotEmpty) {
      setState(() {
        _walletAddress = address;
      });
      prefs.setString(Constants.walletAddressKeySharedPrefs, address);
    }
  }

  Widget _buildWalletAddressInputForm() {
    return Form(
      key: _walletAddressFormKey,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            TextFormField(
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return "Wallet address can't be empty";
                }
                return null;
              },
              decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: "Enter wallet address"),
              onSaved: (address) {
                if (address != null) {
                  _saveWalletAddress(address);
                }
              },
            ),
            const SizedBox(
              height: 8.0,
            ),
            SizedBox(
              width: 150,
              child: ElevatedButton(
                  onPressed: () {
                    if (_walletAddressFormKey.currentState!.validate()) {
                      _walletAddressFormKey.currentState!.save();
                    }
                  },
                  child: const Text("Save")),
            )
          ],
        ),
      ),
    );
  }

  Widget _showNoWalletAddress() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Add a wallet address to begin",
          style: TextStyle(fontSize: 24, color: Theme.of(context).primaryColor),
        ),
        _buildWalletAddressInputForm()
      ],
    );
  }

  Widget _getTabBody() {
    switch (_selectedTabIndex) {
      case 0:
        return const AccountStats();
      case 1:
        return Platform.isAndroid ? const Miner() : const MinerSupport();
      default:
        return const AccountStats();
    }
  }

  @override
  Widget build(BuildContext context) {
    return _walletAddress.isEmpty
        ? _showNoWalletAddress()
        : Column(
            children: [
              Tabs(
                  tabItems: const [
                    TabItem(tabName: 'Stats', iconData: Icons.analytics),
                    TabItem(tabName: 'Mine', iconData: Icons.developer_board)
                  ],
                  selectedIndex: _selectedTabIndex,
                  onItemSelected: (int index) {
                    setState(() {
                      _selectedTabIndex = index;
                    });
                  }),
              Container(child: _getTabBody())
            ],
          );
  }
}
