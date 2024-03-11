import 'package:flutter/material.dart';

class DebugScreenDetailsWidget extends StatelessWidget {
  final String screenName;
  const DebugScreenDetailsWidget({super.key, required this.screenName});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Align(
        alignment: Alignment.bottomLeft,
        child: Container(
          color: Colors.black38,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8.0),
          child: Text(
            screenName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
