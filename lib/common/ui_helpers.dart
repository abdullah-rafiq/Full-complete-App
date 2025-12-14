import 'package:flutter/material.dart';

class UIHelpers {
  const UIHelpers._();

  static void showSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
