import 'package:flutter/material.dart';

void showSafetyNotification(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text("Are you safe?"),
        actions: [
          TextButton(
            onPressed: () {
              // Handle "Yes" action
              Navigator.of(context).pop();
              print("User is safe");
            },
            child: Text("Yes"),
          ),
          TextButton(
            onPressed: () {
              // Handle "No" action
              Navigator.of(context).pop();
              print("User is not safe");
            },
            child: Text("No"),
          ),
        ],
      );
    },
  );
}