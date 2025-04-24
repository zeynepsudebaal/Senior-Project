import 'package:flutter/material.dart';

class ButtonWidget extends StatelessWidget {
  final String text;
  final VoidCallback onClicked;

  const ButtonWidget({
    super.key,
    required this.text,
    required this.onClicked,
  });

  @override
  Widget build(BuildContext context) => ElevatedButton(
    style: ElevatedButton.styleFrom(
      foregroundColor: Colors.green, shape: StadiumBorder(),
      padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
    ),
    onPressed: onClicked,
    child: Text(text),
  );
}