import 'package:ekatapoolcompanion/providers/poolpayment.dart';
import 'package:ekatapoolcompanion/providers/poolstat.dart';
import 'package:ekatapoolcompanion/services/poolpayment.dart';
import 'package:ekatapoolcompanion/utils/common.dart';
import 'package:ekatapoolcompanion/widgets/info_card.dart';
import 'package:ekatapoolcompanion/widgets/payment_widget.dart';
import 'package:flutter/material.dart';
import 'package:matomo_tracker/matomo_tracker.dart';
import 'package:provider/provider.dart';

import '../models/poolpayment.dart';

class Payments extends StatefulWidget {
  const Payments({Key? key}) : super(key: key);

  @override
  State<Payments> createState() => _PaymentsState();
}

class _PaymentsState extends State<Payments> {
  bool _isNewPaymentsLoading = false;

  @override
  void initState() {
    super.initState();
    if (MatomoTracker.instance.initialized) {
      MatomoTracker.instance
          .trackEvent(eventCategory: 'Page Change', action: 'Payments');
    }
  }

  void _onPressLoadMore() {
    var poolPaymentsProvider =
        Provider.of<PoolPaymentProvider>(context, listen: false);
    setState(() {
      _isNewPaymentsLoading = true;
    });
    int timeStamp = poolPaymentsProvider
            .poolPayments[poolPaymentsProvider.poolPayments.length - 1]
            .timeStamp
            .millisecondsSinceEpoch ~/
        1000;
    var newPayments = PoolPaymentService().getPoolPayments(timeStamp);
    newPayments.then((value) {
      poolPaymentsProvider.addPayments(value);
      setState(() {
        _isNewPaymentsLoading = false;
      });
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("There is some issue fetching more pool payments")));
      setState(() {
        _isNewPaymentsLoading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    var poolPayments = Provider.of<PoolPaymentProvider>(context).poolPayments;
    var poolStat = Provider.of<PoolStatProvider>(context).poolStat;
    var hasFetchError = Provider.of<PoolStatProvider>(context).hasFetchError;
    return poolStat != null
        ? ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              getInfoCard(
                  poolStat.pool.totalPayments.toString(), "Total Payment"),
              getInfoCard(
                  poolStat.pool.totalMinersPaid.toString(), "Total Miner Paid"),
              getInfoCard(
                  getReadableCoins(
                      poolStat.config.minPaymentThreshold.toString(),
                      poolStat.config.coinUnits,
                      'BAZA'),
                  "Minimum Payment Threshold",
                  24),
              const SizedBox(
                height: 16,
              ),
              ...poolPayments.asMap().entries.map((e) {
                int id = e.key;
                PoolPayment poolPayment = e.value;
                return PaymentWidget(
                  txHash: poolPayment.hash,
                  timeSent: poolPayment.timeStamp,
                  amount: getReadableCoins(poolPayment.amount.toString(),
                      poolStat.config.coinUnits, 'BAZA'),
                  fee: getReadableCoins(poolPayment.fee.toString(),
                      poolStat.config.coinUnits, 'BAZA'),
                  mixinRequired: poolPayment.mixin,
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
          )
        : Container(
            width: double.infinity,
            height: double.infinity,
            alignment: Alignment.center,
            child: hasFetchError
                ? Text(
                    "There is some issue fetching pool payments, will retry",
                    style: TextStyle(color: Theme.of(context).primaryColor),
                  )
                : const CircularProgressIndicator(),
          );
  }
}
