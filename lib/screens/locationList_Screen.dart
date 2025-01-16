import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:map_view_taskproject/screens/customInfoWindow.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';

class LocationListScreen extends StatefulWidget {
  @override
  _LocationListScreenState createState() => _LocationListScreenState();
}

class _LocationListScreenState extends State<LocationListScreen> {
  late Timer _timer;
  bool _isLoading = false;
  Position? _lastPosition;
  bool _isPermissionGranted = false;

  @override
  void initState() {
    super.initState();
    _requestPermission();

    _timer = Timer.periodic(Duration(minutes: 15), (timer) {
      saveLocation();
    });
  }

  Future<void> _requestPermission() async {
    PermissionStatus status = await Permission.location.request();
    setState(() {
      _isPermissionGranted = status.isGranted;
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  Future<void> saveLocation() async {
    if (!_isPermissionGranted) {
      await _requestPermission();
      if (!_isPermissionGranted) {
        print("Location permission not granted.");
        return;
      }
    }

    try {
      Position position = await Geolocator.getCurrentPosition();

      if (_lastPosition == null ||
          Geolocator.distanceBetween(
                  _lastPosition!.latitude,
                  _lastPosition!.longitude,
                  position.latitude,
                  position.longitude) >
              10) {
        await FirebaseFirestore.instance.collection('locations').add({
          'latitude': position.latitude,
          'longitude': position.longitude,
          'timestamp': FieldValue.serverTimestamp(),
          'userId': FirebaseAuth.instance.currentUser?.uid,
        });

        _lastPosition = position;
      }
    } catch (e) {
      print("Error saving location: $e");
    }
  }

  Future<void> clearLocations() async {
    var locations =
        await FirebaseFirestore.instance.collection('locations').get();
    for (var doc in locations.docs) {
      await doc.reference.delete();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        title: Text('Location Tracker'),
        actions: [
          IconButton(
            icon: Icon(Icons.delete_forever),
            onPressed: () async {
              bool confirmDelete = await showDialog(
                    context: context,
                    builder: (BuildContext context) => AlertDialog(
                      title: Text('Clear Locations'),
                      content: Text(
                          'Are you sure you want to delete all locations?'),
                      actions: <Widget>[
                        TextButton(
                          child: Text('Cancel'),
                          onPressed: () {
                            Navigator.of(context).pop(false);
                          },
                        ),
                        TextButton(
                          child: Text('Delete'),
                          onPressed: () {
                            Navigator.of(context).pop(true);
                          },
                        ),
                      ],
                    ),
                  ) ??
                  false;

              if (confirmDelete) {
                await clearLocations();
              }
            },
          ),
        ],
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('locations')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (_isLoading) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData) {
            return Center(child: Text("No data available"));
          }
          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var location = snapshot.data!.docs[index];
              return ListTile(
                title: Text(
                    "Lat: ${location['latitude']}, Lng: ${location['longitude']}"),
                subtitle:
                    Text(location['timestamp']?.toDate()?.toString() ?? ''),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          CustomInfoWindowScreen(locationId: location.id),
                    ),
                  );
                },
                trailing: IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: () async {
                    await FirebaseFirestore.instance
                        .collection('locations')
                        .doc(location.id)
                        .delete();
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        onPressed: _isLoading
            ? null
            : () async {
                setState(() {
                  _isLoading = true;
                });
                await saveLocation();
                setState(() {
                  _isLoading = false;
                });
              },
        child: Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
