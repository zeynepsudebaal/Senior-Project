import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import 'package:senior_project/pages/chat_page.dart';
import 'package:senior_project/pages/notifications_page.dart';
import 'package:senior_project/pages/showDialog.dart';
import 'package:senior_project/pages/profile_page.dart';

class DashboardPage extends StatefulWidget {
  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  Completer<GoogleMapController> _controller = Completer();

  LatLng? _currentPosition;
  Set<Marker> _markers = {};

  // Google Places API Key (kendine göre değiştir)
  final String _googleApiKey = 'AIzaSyBnqd8vaYcrd3rOLe5fBmmFIV8G8bjaecA';

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error('Location permissions are permanently denied.');
    }

    Position position = await Geolocator.getCurrentPosition();

    setState(() {
      _currentPosition = LatLng(position.latitude, position.longitude);
      // Kendi konum marker'ını ekle (mavi renk)
      _markers = {
        Marker(
          markerId: MarkerId('currentLocation'),
          position: _currentPosition!,
          infoWindow: InfoWindow(title: 'Ben buradayım'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          onTap: () {
            // İstersen kendi konum için de bilgi gösterebilirsin
            _showPlaceInfo(context, 'Ben buradayım', _currentPosition!);
          },
        ),
      };
    });

    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(CameraUpdate.newCameraPosition(
      CameraPosition(target: _currentPosition!, zoom: 15),
    ));

    // Konuma en yakın hastane, eczane ve parkları getir
    await _fetchNearbyPlaces();
  }

  Future<void> _fetchNearbyPlaces() async {
    if (_currentPosition == null) return;

    final lat = _currentPosition!.latitude;
    final lng = _currentPosition!.longitude;

    final baseUrl = 'http://172.20.10.11:3000/api/maps';

    // Önce kendi marker'ı koruyup diğer markerları eklemek için geçici set
    Set<Marker> newMarkers = {
      Marker(
        markerId: MarkerId('currentLocation'),
        position: _currentPosition!,
        infoWindow: InfoWindow(title: 'Buradasınız'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        onTap: () {
          _showPlaceInfo(context, 'Buradasınız', _currentPosition!);
        },
      ),
    };

    // Hastaneleri getir
    final hospitals = await _fetchPlaces('$baseUrl/nearby-hospitals', lat, lng);
    newMarkers.addAll(_createMarkersFromPlaces(hospitals, 'hospital'));

    // Eczaneleri getir
    final pharmacies =
        await _fetchPlaces('$baseUrl/nearby-pharmacies', lat, lng);
    newMarkers.addAll(_createMarkersFromPlaces(pharmacies, 'pharmacy'));

    // Parkları getir
    final parks = await _fetchPlaces('$baseUrl/nearby-parks', lat, lng);
    newMarkers.addAll(_createMarkersFromPlaces(parks, 'park'));

    setState(() {
      _markers = newMarkers;
    });
  }

  Future<List<dynamic>> _fetchPlaces(String url, double lat, double lng) async {
    try {
      final response = await http.get(Uri.parse('$url?lat=$lat&lng=$lng'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['results'] as List<dynamic>;
      } else {
        print('Backend error for $url: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Hata oluştu: $e');
      return [];
    }
  }

  Set<Marker> _createMarkersFromPlaces(List<dynamic> places, String type) {
    BitmapDescriptor icon = _getMarkerIcon(type);

    return places.take(10).map((place) {
      final loc = place['geometry']['location'];
      return Marker(
        markerId: MarkerId(place['place_id']),
        position: LatLng(loc['lat'], loc['lng']),
        infoWindow: InfoWindow(title: place['name'], snippet: type),
        icon: icon,
        onTap: () {
          // Marker tıklanınca info modal aç
          _showPlaceInfo(
              context, place['name'], LatLng(loc['lat'], loc['lng']));
        },
      );
    }).toSet();
  }

  BitmapDescriptor _getMarkerIcon(String type) {
    switch (type) {
      case 'hospital':
        return BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueViolet); // Mor
      case 'pharmacy':
        return BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueYellow); // Sarı
      case 'park':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor
            .hueAzure); // Açık Mavi (hueBlue yerine Azure kullandım)
      default:
        return BitmapDescriptor.defaultMarker;
    }
  }

  void _showPlaceInfo(BuildContext context, String name, LatLng position) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(16),
          height: 180,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name,
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text(
                  'Konum: ${position.latitude.toStringAsFixed(5)}, ${position.longitude.toStringAsFixed(5)}'),
              Spacer(),
              Center(
                child: ElevatedButton.icon(
                  icon: Icon(Icons.directions),
                  label: Text('Git'),
                  onPressed: () async {
                    final url = Uri.parse(
                        'https://www.google.com/maps/dir/?api=1&destination=${position.latitude},${position.longitude}');
                    if (await canLaunchUrl(url)) {
                      await launchUrl(url,
                          mode: LaunchMode.externalApplication);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Harita açılamadı!')),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dashboard'),
      ),
      body: _currentPosition == null
          ? Center(child: CircularProgressIndicator())
          : GoogleMap(
              initialCameraPosition:
                  CameraPosition(target: _currentPosition!, zoom: 15),
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              markers: _markers,
              onMapCreated: (GoogleMapController controller) {
                _controller.complete(controller);
              },
            ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        onTap: (index) {
          switch (index) {
            case 0:
              setState(() {});
              break;
            case 1:
              Navigator.pushReplacement(
                  context, MaterialPageRoute(builder: (_) => ChatScreen()));
              break;
            case 2:
              Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (_) => NotificationPage()));
              break;
            case 3:
              Navigator.pushReplacement(
                  context, MaterialPageRoute(builder: (_) => ProfilePage()));
              break;
          }
        },
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: 'Chat',
          ),
          BottomNavigationBarItem(
              icon: Icon(Icons.notifications), label: 'Notifications'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
