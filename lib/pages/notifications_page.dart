import 'dart:convert';
import 'dart:html' as html; // dart:html'ü import ettik

import 'package:flutter/material.dart';
import 'package:senior_project/pages/chat_page.dart';
import 'package:senior_project/pages/dashboard_page.dart';
import 'package:senior_project/pages/profile_page.dart';

class NotificationPage extends StatefulWidget {
  @override
  _NotificationScreenState createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationPage> {
  List<String> alertMessages = []; // Gelen tüm alert mesajları burada tutulacak
  Map<int, String> userResponses =
      {}; // Her alert için kullanıcının cevabı burada tutulacak
  int _selectedIndex = 2; // Notifications seçili
  html.WebSocket? _socket; // dart:html WebSocket

  void handleResponseForIndex(String response, int index) {
    setState(() {
      userResponses[index] = response;
    });

    print("User Response for alert $index: $response");

    // İstersen bu cevabı backend'e WebSocket ile yollayabilirsin
    if (_socket != null && _socket!.readyState == html.WebSocket.OPEN) {
      final responseData = jsonEncode({
        'type': 'user_response',
        'response': response,
        'alert_index': index,
      });
      _socket!.sendString(responseData);
      print("Sent response to server: $responseData");
    }
  }

  void _connectWebSocket() {
    try {
      _socket = html.WebSocket('ws://10.10.219.112:3000');

      _socket!.onOpen.listen((event) {
        print('WebSocket connected');
      });

      _socket!.onMessage.listen((event) {
        print('Received data from WebSocket: ${event.data}');
        final parsed = jsonDecode(event.data);

        if (parsed['type'] == 'alert') {
          setState(() {
            alertMessages.add(parsed['message']);
          });
        }
      });

      _socket!.onClose.listen((event) {
        print('WebSocket connection closed');
      });

      _socket!.onError.listen((event) {
        print('WebSocket error occurred');
      });
    } catch (e) {
      print('WebSocket connection failed: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    _connectWebSocket();
  }

  @override
  void dispose() {
    _socket?.close();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => DashboardPage()),
        );
        break;
      case 1:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ChatScreen()),
        );
        break;
      case 2:
        // Zaten Notifications sayfasındayız
        break;
      case 3:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ProfilePage()),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 99, 129, 203),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            SizedBox(height: 40),
            Align(
              alignment: Alignment.topCenter,
              child: Text(
                "Notifications",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 5,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: alertMessages.isEmpty
                      ? Text(
                          "No alerts yet.",
                          style: TextStyle(fontSize: 16),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          itemCount: alertMessages.length,
                          itemBuilder: (context, index) {
                            final message = alertMessages[index];
                            return Card(
                              margin: EdgeInsets.symmetric(vertical: 8),
                              child: Padding(
                                padding: EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      message,
                                      style: TextStyle(fontSize: 16),
                                    ),
                                    SizedBox(height: 10),
                                    Text(
                                      "Are you safe?",
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: 10),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      children: [
                                        ElevatedButton(
                                          onPressed: () =>
                                              handleResponseForIndex(
                                                  "Yes", index),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.green,
                                            padding: EdgeInsets.symmetric(
                                                horizontal: 20, vertical: 8),
                                          ),
                                          child: Text("Yes"),
                                        ),
                                        ElevatedButton(
                                          onPressed: () =>
                                              handleResponseForIndex(
                                                  "No", index),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.red,
                                            padding: EdgeInsets.symmetric(
                                                horizontal: 20, vertical: 8),
                                          ),
                                          child: Text("No"),
                                        ),
                                      ],
                                    ),
                                    if (userResponses.containsKey(index))
                                      Padding(
                                        padding: EdgeInsets.only(top: 10),
                                        child: Text(
                                          "Your response: ${userResponses[index]}",
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: "Dashboard",
          ),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: "Chat"),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: "Notifications",
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }
}
