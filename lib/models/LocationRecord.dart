// Creamos un modelo simple para guardar la información de cada registro.

class LocationRecord {
  final double latitude;
  final double longitude;
  final DateTime timestamp;

  LocationRecord({
    required this.latitude,
    required this.longitude,
    required this.timestamp,
  });
}
