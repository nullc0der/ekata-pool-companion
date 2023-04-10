import 'dart:async';
import 'dart:convert';

import 'package:ekatapoolcompanion/models/minerconfig.dart';
import 'package:ekatapoolcompanion/pages/miner/miner.dart';
import 'package:ekatapoolcompanion/providers/minerstatus.dart';
import 'package:ekatapoolcompanion/services/minerconfig.dart';
import 'package:ekatapoolcompanion/utils/common.dart';
import 'package:ekatapoolcompanion/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserMinerConfig extends StatefulWidget {
  const UserMinerConfig({Key? key, required this.setCurrentWizardStep})
      : super(key: key);

  final ValueChanged<WizardStep> setCurrentWizardStep;

  @override
  State<UserMinerConfig> createState() => _UserMinerConfigState();
}

class _UserMinerConfigState extends State<UserMinerConfig> {
  List<UsersMinerConfig> _minerConfigs = [];
  bool _hasMinerConfigsFetchError = false;
  bool _minerConfigFetching = false;
  String _searchQueryString = "";
  DateTimeRange? _filterDateTimeRange;
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _getUserMinerConfigs();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }

  Future<void> _getUserMinerConfigs(
      {String? queryString, String? fromDate, String? toDate}) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString(Constants.userIdSharedPrefs);
    if (userId != null) {
      setState(() {
        _minerConfigFetching = true;
        _hasMinerConfigsFetchError = false;
      });
      try {
        final minerConfigs = await MinerConfigService.getMinerConfig(
            userId: userId,
            queryString: queryString,
            fromDate: fromDate,
            toDate: toDate);
        setState(() {
          _minerConfigs = minerConfigs;
          _minerConfigFetching = false;
          _hasMinerConfigsFetchError = false;
        });
      } on Exception {
        setState(() {
          _minerConfigFetching = false;
          _hasMinerConfigsFetchError = true;
        });
      }
    }
  }

  Future<UsersMinerConfig> _getFinalMinerConfig(
      UsersMinerConfig usersMinerConfig) async {
    // TODO: Need to test if pool cred found properly
    final prefs = await SharedPreferences.getInstance();
    final poolCredentialsPrefs =
        prefs.getString(Constants.poolCredentialsSharedPrefs);
    if (poolCredentialsPrefs != null) {
      final Map<String, dynamic> poolCredentials =
          jsonDecode(poolCredentialsPrefs);
      if (poolCredentials.containsKey(usersMinerConfig.minerConfigMd5)) {
        final List<Map<String, dynamic>> newPools = [];
        for (final pool in usersMinerConfig.minerConfig["pools"]) {
          final credentials =
              poolCredentials[usersMinerConfig.minerConfigMd5][pool["url"]];
          if (credentials.isNotEmpty) {
            newPools.add({
              ...pool,
              "user": credentials["user"],
              "pass": credentials["pass"]
            });
          }
          if (newPools.isNotEmpty) {
            usersMinerConfig.minerConfig["pools"] = newPools;
          }
        }
      }
    }
    return usersMinerConfig;
  }

  Future<void> _onPressStartMining(UsersMinerConfig usersMinerConfig) async {
    final finalUsersMinerConfig = await _getFinalMinerConfig(usersMinerConfig);
    final minerConfigString = jsonEncode(finalUsersMinerConfig.minerConfig);
    final filePath = await saveMinerConfigToFile(minerConfigString);
    final minerConfig = minerConfigFromJson(minerConfigString);
    Provider.of<MinerStatusProvider>(context, listen: false).minerConfig =
        minerConfig;
    Provider.of<MinerStatusProvider>(context, listen: false).minerConfigPath =
        filePath;
    // Provider.of<UiStateProvider>(context, listen: false).showBottomNavbar =
    //     minerConfig.pools.first.url == "70.35.206.105:3333" ||
    //         minerConfig.pools.first.url == "70.35.206.105:5555";
    // Provider.of<UiStateProvider>(context, listen: false).bottomNavigationIndex =
    //     3;
    widget.setCurrentWizardStep(WizardStep.miner);
  }

  Future<void> _onPressEditMinerConfig(
      UsersMinerConfig usersMinerConfig) async {
    Provider.of<MinerStatusProvider>(context, listen: false).usersMinerConfig =
        await _getFinalMinerConfig(usersMinerConfig);
    widget.setCurrentWizardStep(WizardStep.minerConfig);
  }

  Future<void> _onPressDeleteMinerConfig(
      UsersMinerConfig usersMinerConfig) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString(Constants.userIdSharedPrefs);
    if (userId != null) {
      try {
        final deleted = await MinerConfigService.deleteMinerConfig(
            userId: userId, minerConfigMd5: usersMinerConfig.minerConfigMd5);
        if (deleted) {
          final poolCredentialsPrefs =
              prefs.getString(Constants.poolCredentialsSharedPrefs);
          if (poolCredentialsPrefs != null) {
            final Map<String, dynamic> poolCredentialPrefsDecoded =
                jsonDecode(poolCredentialsPrefs);
            if (poolCredentialPrefsDecoded
                .containsKey(usersMinerConfig.minerConfigMd5)) {
              poolCredentialPrefsDecoded
                  .remove(usersMinerConfig.minerConfigMd5);
            }
            prefs.setString(Constants.poolCredentialsSharedPrefs,
                jsonEncode(poolCredentialPrefsDecoded));
          }
          setState(() {
            _minerConfigs = _minerConfigs
                .where((element) =>
                    element.minerConfigMd5 != usersMinerConfig.minerConfigMd5)
                .toList();
          });
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text("MinerConfig deleted successfully")));
        }
      } on Exception catch (_) {}
    }
  }

  Widget _renderOneMinerConfig(UsersMinerConfig minerConfig) {
    final List pools = minerConfig.minerConfig["pools"];
    return Card(
      shadowColor: Colors.transparent,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(children: [
          if (minerConfig.timeStamp != null)
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Chip(
                    shape: const StadiumBorder(),
                    avatar: const Icon(Icons.timer, size: 16),
                    label: Text(
                      DateFormat.yMd().add_jm().format(
                          DateTime.fromMillisecondsSinceEpoch(
                              minerConfig.timeStamp!)),
                    )),
              ],
            ),
          const SizedBox(
            height: 8,
          ),
          ...pools.asMap().entries.map((entry) {
            final pool = entry.value;
            return Column(
              children: [
                if (entry.key % 2 != 0)
                  const SizedBox(
                    height: 4,
                  ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 2,
                      children: [
                        const Icon(
                          Icons.link,
                          size: 20,
                        ),
                        Text("Pool Address",
                            style: Theme.of(context).textTheme.titleMedium),
                      ],
                    ),
                    Text(
                      pool["url"],
                      style: Theme.of(context).textTheme.labelMedium,
                    )
                  ],
                ),
                const SizedBox(
                  height: 8,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 2,
                      children: [
                        const Icon(Icons.developer_board, size: 20),
                        Text(
                          "Algo",
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                    Text(
                      pool["algo"],
                      style: Theme.of(context).textTheme.labelMedium,
                    )
                  ],
                ),
                if (entry.key % 2 == 0 && pools.length != entry.key + 1)
                  const SizedBox(
                    height: 4,
                  ),
                if (pools.length != entry.key + 1)
                  Divider(
                    thickness: 1,
                    indent: 20,
                    endIndent: 20,
                    color: Theme.of(context).primaryColor,
                  )
              ],
            );
          }),
          const SizedBox(
            height: 8,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                  onPressed: () => _onPressDeleteMinerConfig(minerConfig),
                  child: Wrap(
                    spacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: const [
                      Icon(
                        Icons.delete,
                        size: 18,
                      ),
                      Text("Delete")
                    ],
                  )),
              const SizedBox(
                width: 4,
              ),
              TextButton(
                child: Wrap(
                  spacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: const [
                    Icon(
                      Icons.arrow_forward,
                      size: 18,
                    ),
                    Text("Edit")
                  ],
                ),
                onPressed: () => _onPressEditMinerConfig(minerConfig),
              ),
              const SizedBox(
                width: 4,
              ),
              FilledButton(
                  onPressed: () => _onPressStartMining(minerConfig),
                  child: Wrap(
                    spacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: const [
                      Icon(
                        Icons.check,
                        size: 18,
                      ),
                      Text("Use")
                    ],
                  )),
            ],
          )
        ]),
      ),
    );
  }

  Widget _minerConfigSearchForm() {
    return TextField(
      decoration:
          const InputDecoration(labelText: "Search by pool url or algo"),
      onChanged: (value) {
        if (_searchDebounce?.isActive ?? false) _searchDebounce?.cancel();
        _searchDebounce = Timer(const Duration(milliseconds: 500), () {
          if (value.length >= 3) {
            _getUserMinerConfigs(
                queryString: value,
                fromDate: _filterDateTimeRange?.start.millisecondsSinceEpoch
                    .toString(),
                toDate: _filterDateTimeRange?.end
                    .add(const Duration(days: 1))
                    .millisecondsSinceEpoch
                    .toString());
          }
          if (value.isEmpty) {
            _getUserMinerConfigs(
                fromDate: _filterDateTimeRange?.start.millisecondsSinceEpoch
                    .toString(),
                toDate: _filterDateTimeRange?.end
                    .add(const Duration(days: 1))
                    .millisecondsSinceEpoch
                    .toString());
          }
          setState(() {
            _searchQueryString = value;
          });
        });
      },
    );
  }

  Widget _dateRangeFilter() {
    return GestureDetector(
      child: Container(
          padding: const EdgeInsets.all(16),
          width: double.infinity,
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Theme.of(context).primaryColor)),
          child: Row(
            children: [
              Icon(
                Icons.calendar_month,
                color: Theme.of(context).primaryColor,
                size: 16,
              ),
              const SizedBox(
                width: 4,
              ),
              _filterDateTimeRange != null &&
                      _filterDateTimeRange?.start != null &&
                      _filterDateTimeRange?.end != null
                  ? Text(
                      "${DateFormat.yMd().format(_filterDateTimeRange!.start)} - ${DateFormat.yMd().format(_filterDateTimeRange!.end)}")
                  : const Text("Filter by date range"),
              if (_filterDateTimeRange != null) ...[
                const Spacer(),
                TextButton(
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: () {
                      setState(() {
                        _filterDateTimeRange = null;
                      });
                      _getUserMinerConfigs(queryString: _searchQueryString);
                    },
                    child: Icon(
                      Icons.cancel,
                      color: Theme.of(context).primaryColor,
                      size: 16,
                    ))
              ]
            ],
          )),
      onTap: () async {
        final dateTimeRange = await showDateRangePicker(
            context: context,
            initialDateRange: _filterDateTimeRange,
            firstDate: DateTime(2023, 1, 1),
            lastDate: DateTime.now());
        if (dateTimeRange != null) {
          setState(() {
            _filterDateTimeRange = dateTimeRange;
          });
          _getUserMinerConfigs(
              queryString: _searchQueryString,
              fromDate: dateTimeRange.start.millisecondsSinceEpoch.toString(),
              toDate: dateTimeRange.end
                  .add(const Duration(days: 1))
                  .millisecondsSinceEpoch
                  .toString());
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Saved Miner Configs",
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(
            height: 8,
          ),
          _minerConfigSearchForm(),
          const SizedBox(
            height: 8,
          ),
          _dateRangeFilter(),
          const SizedBox(
            height: 8,
          ),
          Expanded(
              child: !_minerConfigFetching
                  ? _minerConfigs.isNotEmpty
                      ? ListView(
                          children: _minerConfigs
                              .map((e) => _renderOneMinerConfig(e))
                              .toList(),
                        )
                      : Container(
                          alignment: Alignment.center,
                          child: Text(
                              "It seems you don't have any saved miner configs",
                              style: Theme.of(context).textTheme.labelLarge),
                        )
                  : Container(
                      alignment: Alignment.center,
                      child: _hasMinerConfigsFetchError
                          ? Text("There is some issue fetching saved configs",
                              style: Theme.of(context).textTheme.labelLarge)
                          : const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(),
                            ))),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                  style:
                      ElevatedButton.styleFrom(shadowColor: Colors.transparent),
                  onPressed: () =>
                      widget.setCurrentWizardStep(WizardStep.coinNameSelect),
                  child: const Icon(Icons.arrow_back)),
            ],
          )
        ],
      ),
    );
  }
}
