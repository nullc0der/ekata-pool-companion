import 'package:ekatapoolcompanion/widgets/custom_expansion_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class PaymentWidget extends StatelessWidget {
  const PaymentWidget(
      {Key? key,
      required this.txHash,
      required this.timeSent,
      required this.amount,
      required this.fee,
      this.mixinRequired,
      this.margin,
      required this.initiallyExpanded})
      : super(key: key);

  final String txHash;
  final DateTime timeSent;
  final String amount;
  final String fee;
  final int? mixinRequired;
  final EdgeInsetsGeometry? margin;
  final bool initiallyExpanded;

  void _onLongPressTxHash(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text)).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Transaction hash copied to clipboard")));
    });
  }

  Widget _buildPaymentWidgetExpandedChild(String txHash, DateTime timeSent,
      String fee, int? mixinRequired, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text("Tx hash"),
                flex: 1,
              ),
              Expanded(
                  child: GestureDetector(
                onLongPress: () {
                  return _onLongPressTxHash(context, txHash);
                },
                child: Text(txHash),
              )),
            ],
          ),
          Divider(
            color: Theme.of(context).primaryColor,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Time Sent"),
              Text(DateFormat.yMd().add_jm().format(timeSent)),
            ],
          ),
          Divider(
            color: Theme.of(context).primaryColor,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Fee"),
              Text(fee),
            ],
          ),
          Visibility(
            child: Divider(
              color: Theme.of(context).primaryColor,
            ),
            visible: mixinRequired != null,
          ),
          Visibility(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Mixin"),
                  Text("$mixinRequired"),
                ],
              ),
              visible: mixinRequired != null),
          const SizedBox(
            height: 12,
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CustomExpansionTile(
      title: Text("Tx Hash: ${txHash.substring(txHash.length - 10)}"),
      trailing: const Text(""),
      subtitle: Text("Amount: $amount"),
      margin: margin,
      children: [
        _buildPaymentWidgetExpandedChild(
            txHash, timeSent, fee, mixinRequired, context)
      ],
      textColor: Theme.of(context).primaryColor,
      collapsedTextColor: Theme.of(context).primaryColor,
      backgroundColor: const Color(0xFFEBF1FD),
      collapsedBackgroundColor: const Color(0xFFEBF1FD),
      initiallyExpanded: initiallyExpanded,
    );
  }
}
