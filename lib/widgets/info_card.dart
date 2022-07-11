import 'package:flutter/material.dart';

Widget getInfoCard(String title, String subTitle,
    [double titleFontSize = 32, double subTitleFontSize = 12]) {
  return Container(
    margin: const EdgeInsets.only(top: 16, right: 8, left: 8),
    padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 12),
    decoration: BoxDecoration(
        //color: const Color(0xFF233349),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF233349), Color(0xFF526174)],
        ),
        boxShadow: const [
          BoxShadow(
              blurRadius: 12,
              spreadRadius: 4,
              color: Color.fromRGBO(0, 0, 0, 0.23))
        ],
        borderRadius: BorderRadius.circular(6)),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title,
            style: TextStyle(color: Colors.white, fontSize: titleFontSize)),
        Text(subTitle,
            style: TextStyle(color: Colors.white, fontSize: subTitleFontSize))
      ],
    ),
  );
}
