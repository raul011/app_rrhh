import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Registro de Ubicación',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: const LocationHomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

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

class LocationHomePage extends StatefulWidget {
  const LocationHomePage({super.key});

  @override
  State<LocationHomePage> createState() => _LocationHomePageState();
}

class _LocationHomePageState extends State<LocationHomePage> {
  // Una lista para almacenar todos los registros que hagamos.
  final List<LocationRecord> _locationRecords = [];
  // NUEVO: Controlador para el campo de texto del nombre.
  final TextEditingController _nameController = TextEditingController();
  bool _isLoading = false;

  // --- Función para enviar el registro al servidor Laravel ---
  // MODIFICADO: Ahora acepta el nombre como parámetro.
  Future<void> _sendRecordToServer(LocationRecord record, String name) async {
    // IMPORTANTE: Reemplaza esta URL con la URL de tu tenant.
    // Si usas un emulador de Android y tu servidor Laravel corre en `localhost:8000`,
    // la IP para acceder desde el emulador es 10.0.2.2.
    // Ejemplo: 'http://empresa1.localhost/api/location-records'
    // Para que funcione con el emulador y el dominio del tenant, puedes usar nip.io:
    // Para que el dominio del tenant funcione, puedes usar nip.io:
    const String apiUrl =
        //'http://empresa1.10.0.2.2.nip.io:8000/api/location-records';
        //   'http://empresa1.192.168.0.184:8000/api/location-records';
        'http://192.168.0.184:8000/api/location-records';

    try {
      // MODIFICADO: Añadimos el nombre al cuerpo de la petición.
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'name': name,
          'latitude': record.latitude,
          'longitude': record.longitude,
          // Formato ISO 8601 que Laravel entiende sin problemas.
          'recorded_at': record.timestamp.toIso8601String(),
        }),
      );

      if (response.statusCode == 201) {
        print('Registro enviado al servidor con éxito.');
      } else {
        print('Error al enviar el registro: ${response.statusCode}');
        print('Cuerpo de la respuesta: ${response.body}');
      }
    } catch (e) {
      print('Excepción al conectar con el servidor: $e');
    }
  }

  // --- Función principal para obtener la ubicación y registrarla ---
  Future<void> _getCurrentLocationAndRecord() async {
    // Mostramos un indicador de carga mientras se obtiene la ubicación.

    // NUEVO: Validar que el nombre no esté vacío.
    if (_nameController.text.trim().isEmpty) {
      _showError('Por favor, ingresa tu nombre.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // 1. Comprobar si los servicios de ubicación están habilitados.
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        // Si no están habilitados, mostramos un error.
        _showError('Los servicios de ubicación están deshabilitados.');
        return;
      }

      // 2. Comprobar y solicitar permisos.
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showError('Los permisos de ubicación fueron denegados.');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showError(
          'Los permisos de ubicación están permanentemente denegados, no podemos solicitar permisos.',
        );
        return;
      }

      // 3. Si tenemos permisos, obtenemos la ubicación actual.
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // 4. Creamos un nuevo registro y lo añadimos a nuestra lista.
      final newRecord = LocationRecord(
        latitude: position.latitude,
        longitude: position.longitude,
        timestamp: DateTime.now(),
      );

      // Usamos setState para que la UI se actualice con el nuevo registro.
      setState(() {
        _locationRecords.insert(
          0,
          newRecord,
        ); // Insertamos al inicio para ver el más nuevo primero.
      });

      // 5. Enviamos el registro al servidor (sin esperar la respuesta para no bloquear la UI)
      _sendRecordToServer(
        newRecord,
        _nameController.text.trim(),
      ); // MODIFICADO: Pasamos el nombre.
    } catch (e) {
      // Manejo de cualquier otro error.
      _showError('Ocurrió un error al obtener la ubicación: $e');
    } finally {
      // Ocultamos el indicador de carga.
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Función auxiliar para mostrar mensajes de error con un SnackBar.
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  // NUEVO: Liberar el controlador cuando el widget se destruye.
  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registro de Ubicación'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          // --- NUEVO: Campo de texto para el nombre ---
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
            child: TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nombre del Empleado',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
              textCapitalization: TextCapitalization.words,
            ),
          ),
          // --- Botón para registrar la ubicación ---
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon:
                    _isLoading
                        ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                        : const Icon(Icons.location_on),
                label: Text(
                  _isLoading ? 'Obteniendo...' : 'Registrar Ubicación y Hora',
                ),
                onPressed: _isLoading ? null : _getCurrentLocationAndRecord,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  textStyle: const TextStyle(fontSize: 16),
                ),
              ),
            ),
          ),
          const Divider(),
          // --- Lista de registros ---
          Expanded(
            child:
                _locationRecords.isEmpty
                    ? const Center(
                      child: Text(
                        'Aún no hay registros.\nPresiona el botón para empezar.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    )
                    : ListView.builder(
                      itemCount: _locationRecords.length,
                      itemBuilder: (context, index) {
                        final record = _locationRecords[index];
                        // Formateamos la fecha y hora para que sea fácil de leer.
                        final formattedDate = DateFormat(
                          'dd/MM/yyyy',
                        ).format(record.timestamp);
                        final formattedTime = DateFormat(
                          'HH:mm:ss',
                        ).format(record.timestamp);

                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 6,
                          ),
                          child: ListTile(
                            leading: const Icon(
                              Icons.pin_drop,
                              color: Colors.blue,
                            ),
                            title: Text(
                              'Fecha: $formattedDate - Hora: $formattedTime',
                            ),
                            subtitle: Text(
                              'Lat: ${record.latitude.toStringAsFixed(4)}, Lon: ${record.longitude.toStringAsFixed(4)}',
                            ),
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }
}
