import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class LocationHistoryScreen extends StatefulWidget {
  final String userId;

  LocationHistoryScreen({required this.userId});

  @override
  _LocationHistoryScreenState createState() => _LocationHistoryScreenState();
}

class _LocationHistoryScreenState extends State<LocationHistoryScreen> {
  late GoogleMapController _controller;
  Set<Marker> _markers = {};
  Polyline? _polyline;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        title: Text('Location History'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('locations')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final locations = snapshot.data?.docs ?? [];

          _markers.clear();
          List<LatLng> polylinePoints = [];

          for (var locationDoc in locations) {
            double latitude = locationDoc['latitude'];
            double longitude = locationDoc['longitude'];

            _markers.add(
              Marker(
                markerId: MarkerId(locationDoc.id),
                position: LatLng(latitude, longitude),
                infoWindow: InfoWindow(
                  title: 'Location: ${locationDoc['timestamp']}',
                  snippet: 'Lat: $latitude, Lng: $longitude',
                ),
              ),
            );

            polylinePoints.add(LatLng(latitude, longitude));
          }

          if (polylinePoints.isNotEmpty) {
            _polyline = Polyline(
              polylineId: PolylineId('locationPath'),
              points: polylinePoints,
              color: Colors.blue,
              width: 5,
            );
          }

          if (_markers.isEmpty) {
            return Center(child: Text('No location history available.'));
          }

          LatLng initialPosition = LatLng(
            locations.first['latitude'],
            locations.first['longitude'],
          );

          return GoogleMap(
            onMapCreated: (GoogleMapController controller) {
              _controller = controller;
              _controller.animateCamera(
                  CameraUpdate.newLatLngZoom(initialPosition, 12));
            },
            initialCameraPosition: CameraPosition(
              target: initialPosition,
              zoom: 12,
            ),
            markers: _markers,
            polylines: _polyline != null ? {_polyline!} : {},
          );
        },
      ),
    );
  }
}
