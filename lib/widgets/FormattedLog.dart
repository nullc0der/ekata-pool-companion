import 'package:ekatapoolcompanion/models/logtext.dart';
import 'package:flutter/material.dart';

class FormattedLog extends StatelessWidget {
  const FormattedLog({Key? key, required this.logTexts}) : super(key: key);

  final List<List<LogText>> logTexts;

  @override
  Widget build(BuildContext context) {
    return logTexts.isNotEmpty
        ? Wrap(
            children: logTexts
                .map((e) => Wrap(
                      children: e
                          .map((e) => Container(
                                padding: const EdgeInsets.all(1),
                                child: Text(
                                  e.text,
                                  style: TextStyle(
                                      color: e.logFormatDecoration.fgColor,
                                      backgroundColor:
                                          e.logFormatDecoration.bgColor,
                                      fontWeight: e.logFormatDecoration.isBold
                                          ? FontWeight.bold
                                          : FontWeight.normal),
                                ),
                              ))
                          .toList(),
                    ))
                .toList(),
          )
        : Container();
  }
}
