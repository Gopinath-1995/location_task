import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:map_view_taskproject/screens/locationHistoryscreen.dart';

class CustomInfoWindowScreen extends StatefulWidget {
  final String locationId;

  CustomInfoWindowScreen({required this.locationId});

  @override
  _CustomInfoWindowScreenState createState() => _CustomInfoWindowScreenState();
}

class _CustomInfoWindowScreenState extends State<CustomInfoWindowScreen> {
  late GoogleMapController _controller;
  LatLng _markerPosition = LatLng(0, 0);
  String _infoWindowText = "";
  String _townImageUrl = "";
  List<LatLng> _locationHistory = [];
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _fetchLocationData();
  }

  Future<void> _fetchLocationData() async {
    var locationData = await FirebaseFirestore.instance
        .collection('locations')
        .doc(widget.locationId)
        .get();

    if (locationData.exists) {
      var data = locationData.data();
      double latitude = data?['latitude'] ?? 0.0;
      double longitude = data?['longitude'] ?? 0.0;
      String timestamp = data?['timestamp']?.toDate()?.toString() ?? '';
      String townImageUrl = data?['townImageUrl'] ?? '';

      setState(() {
        _markerPosition = LatLng(latitude, longitude);
        _infoWindowText =
            "Lat: $latitude, Lng: $longitude\nTimestamp: $timestamp";
        _townImageUrl = townImageUrl;
      });

      _controller
          .animateCamera(CameraUpdate.newLatLngZoom(_markerPosition, 15));
    }

    _fetchLocationHistory();
  }

  Future<void> _fetchLocationHistory() async {
    var historyData = await FirebaseFirestore.instance
        .collection('locationHistory')
        .doc(widget.locationId)
        .get();

    if (historyData.exists) {
      var data = historyData.data();
      List<LatLng> history = List<LatLng>.from(
        data?['history']
                ?.map((item) => LatLng(item['latitude'], item['longitude'])) ??
            [],
      );

      setState(() {
        _locationHistory = history;
      });
    }
  }

  Future<void> _playbackRoute() async {
    if (_locationHistory.isEmpty) {
      print("No location history found.");
      return;
    }

    for (int i = _currentIndex; i < _locationHistory.length; i++) {
      final LatLng currentLocation = _locationHistory[i];
      await _controller.animateCamera(CameraUpdate.newLatLng(currentLocation));

      setState(() {
        _currentIndex = i + 1;
      });

      await Future.delayed(Duration(seconds: 1));
    }
  }

  void _navigateToLocationHistory() {
    String userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LocationHistoryScreen(
          userId: userId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        title: Text('Location on Map'),
      ),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: (GoogleMapController controller) {
              _controller = controller;
            },
            initialCameraPosition: CameraPosition(
              target: _markerPosition,
              zoom: 15,
            ),
            markers: {
              Marker(
                markerId: MarkerId('locationMarker'),
                position: _markerPosition,
                infoWindow: InfoWindow(
                  title: 'Location Info',
                  snippet: _infoWindowText,
                ),
              ),
            },
          ),
          _buildCustomInfoWindow(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        onPressed: _navigateToLocationHistory,
        child: Icon(Icons.play_arrow, color: Colors.white),
      ),
    );
  }

  Widget _buildCustomInfoWindow() {
    return Positioned(
      bottom: 30,
      left: 50,
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: EdgeInsets.all(8),
          color: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Custom Info Window',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 5),
              Text(
                _infoWindowText,
                style: TextStyle(fontSize: 14),
              ),
              SizedBox(height: 10),
              _townImageUrl.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        _townImageUrl,
                        width: 150,
                        height: 100,
                        fit: BoxFit.cover,
                      ),
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Center(
                        child: Image.network(
                          'https://www.spellholiday.com/wp-content/uploads/2018/06/madurai-1.jpg',
                          width: 150,
                          height: 100,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
