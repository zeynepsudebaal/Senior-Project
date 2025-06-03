import 'package:flutter/material.dart';

class ButtonWidget extends StatelessWidget {
  final String text;
  final VoidCallback onClicked;
  final ButtonStyle? style;

  const ButtonWidget({
    Key? key,
    required this.text,
    required this.onClicked,
    this.style,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) => ElevatedButton(
    style: style ?? ElevatedButton.styleFrom(
      foregroundColor: Colors.green,
      shape: StadiumBorder(),
      padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
    ),
    child: Text(text),
    onPressed: onClicked,
  );
}