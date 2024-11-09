import 'package:flutter/material.dart';

void moveToPage(BuildContext context, Widget newPage, bool replacement) {
  if (replacement) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => newPage),
    );
  } else {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => newPage),
    );
  }
}
