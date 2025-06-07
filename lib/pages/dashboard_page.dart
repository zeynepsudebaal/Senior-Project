import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';

class DashboardPage extends StatefulWidget {
  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  LatLng? _currentPosition;
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};

  // Popup için seçili yer bilgisi
  Map<String, dynamic>? _selectedPlace;

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  double getMarkerHue(String type) {
    switch (type) {
      case 'hospitals':
        return BitmapDescriptor.hueRed;
      case 'pharmacies':
        return BitmapDescriptor.hueYellow;
      case 'parks':
        return BitmapDescriptor.hueGreen;
      default:
        return BitmapDescriptor.hueOrange;
    }
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showLocationServiceDialog();
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _showSnackBar('Konum izni reddedildi');
        return;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      _showSnackBar(
          'Konum izni kalıcı olarak reddedildi. Ayarlardan izinleri açmanız gerekiyor.');
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      _currentPosition = LatLng(position.latitude, position.longitude);

      _markers.clear();

      _markers.add(
        Marker(
          markerId: MarkerId('currentLocation'),
          position: _currentPosition!,
          infoWindow: InfoWindow(title: 'Konumunuz'),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueAzure,
          ),
          onTap: () {
            setState(() {
              _selectedPlace = {
                'name': 'Konumunuz',
                'address': '',
                'lat': _currentPosition!.latitude,
                'lng': _currentPosition!.longitude,
              };
            });
            _showPlaceBottomSheet();
          },
        ),
      );

      await _fetchNearbyPlaces();

      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(_currentPosition!, 15),
      );

      setState(() {});
    } catch (e) {
      _showSnackBar('Konum alınamadı: $e');
    }
  }

  Future<void> _fetchNearbyPlaces() async {
    final lat = _currentPosition!.latitude;
    final lng = _currentPosition!.longitude;
    final url =
        Uri.parse('http://172.20.10.2:3000/api/map/nearby?lat=$lat&lng=$lng');

    try {
      final resp = await http.get(url);

      if (resp.statusCode == 200) {
        final data = json.decode(resp.body);
        data.forEach((type, places) {
          for (var place in places) {
            final loc = place['location'];
            final markerId = MarkerId('$type-${place['place_id']}');
            _markers.add(
              Marker(
                markerId: markerId,
                position: LatLng(loc['lat'], loc['lng']),
                infoWindow: InfoWindow(
                  title: place['name'],
                  snippet: place['address'],
                ),
                icon: BitmapDescriptor.defaultMarkerWithHue(
                  getMarkerHue(type),
                ),
                onTap: () {
                  setState(() {
                    _selectedPlace = {
                      'name': place['name'],
                      'address': place['address'],
                      'lat': loc['lat'],
                      'lng': loc['lng'],
                    };
                  });
                  _showPlaceBottomSheet();
                },
              ),
            );
          }
        });
        setState(() {});
      } else {
        _showSnackBar('Yakın yerler alınamadı: ${resp.statusCode}');
      }
    } catch (e) {
      _showSnackBar('Yakın yerler alınırken hata: $e');
    }
  }

  void _showPlaceBottomSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        final place = _selectedPlace!;
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Wrap(
            children: [
              Text(
                place['name'] ?? '',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(place['address'] ?? ''),
              SizedBox(height: 16),
              ElevatedButton.icon(
                icon: Icon(Icons.map),
                label: Text('Google Maps\'te Aç'),
                onPressed: () {
                  final lat = place['lat'];
                  final lng = place['lng'];
                  final googleMapsUrl =
                      'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=walking';

                  _launchUrl(googleMapsUrl);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      _showSnackBar('Google Maps açılamadı');
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    if (_currentPosition != null) {
      _mapController!
          .animateCamera(CameraUpdate.newLatLngZoom(_currentPosition!, 15));
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _showLocationServiceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Konum Servisi Kapalı'),
        content: Text('Lütfen konum servisini açınız.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Tamam'),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendRow(Color color, String label) {
    return Row(
      children: [
        Icon(Icons.place, size: 16, color: color),
        SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 12)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dashboard'),
      ),
      body: Stack(
        children: [
          if (_currentPosition == null)
            Center(child: CircularProgressIndicator())
          else
            GoogleMap(
              onMapCreated: _onMapCreated,
              initialCameraPosition: CameraPosition(
                target: _currentPosition!,
                zoom: 15,
              ),
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              markers: _markers,
            ),
          Positioned(
            right: 12,
            bottom: 12,
            child: Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white70,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLegendRow(Colors.green, 'Park'),
                  SizedBox(height: 4),
                  _buildLegendRow(Colors.red, 'Hastane'),
                  SizedBox(height: 4),
                  _buildLegendRow(Colors.yellow, 'Eczane'),
                  SizedBox(height: 4),
                  _buildLegendRow(Colors.blueAccent, 'Kendi Konumunuz'),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _determinePosition,
        tooltip: 'Konumu Yenile',
        child: Icon(Icons.my_location),
      ),
    );
  }
}
