import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class LocationDatabase {
  static Future<Database> initializeDB() async {
    String path = await getDatabasesPath();
    return openDatabase(
      join(path, 'location.db'),
      onCreate: (database, version) async {
        await database.execute(
          'CREATE TABLE locations(id INTEGER PRIMARY KEY, latitude REAL, longitude REAL, timestamp TEXT)',
        );
      },
      version: 1,
    );
  }

  static Future<void> insertLocation(double latitude, double longitude) async {
    final db = await initializeDB();
    await db.insert('locations', {
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  static Future<List<Map<String, dynamic>>> fetchLocations() async {
    final db = await initializeDB();
    return db.query('locations');
  }
}
