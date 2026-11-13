import 'dart:async';
import 'package:geolocator/geolocator.dart';

class GpsService {
  GpsService._();
  static final instance = GpsService._();

  Future<Position> ambilLokasi() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw Exception('Aktifkan layanan lokasi perangkat');
    }

    var izin = await Geolocator.checkPermission();
    if (izin == LocationPermission.denied) {
      izin = await Geolocator.requestPermission();
      if (izin == LocationPermission.denied ||
          izin == LocationPermission.deniedForever) {
        throw Exception('Izin lokasi tidak diberikan');
      }
    }

    if (izin == LocationPermission.deniedForever) {
      throw Exception('Izin lokasi tidak diberikan');
    }

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 30),
      ),
    );
  }
}