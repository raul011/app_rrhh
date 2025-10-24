import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:si2/models/LocationRecord.dart';
import 'package:si2/services/session_service.dart';

class LocationHomePage extends StatefulWidget {
  const LocationHomePage({super.key});

  @override
  State<LocationHomePage> createState() => _LocationHomePageState();
}

class _LocationHomePageState extends State<LocationHomePage> {
  // Una lista para almacenar todos los registros que hagamos.
  final List<LocationRecord> _locationRecords = [];
  // NUEVO: Controlador para el campo de texto del nombre.
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
        'http://empresa1.192.168.0.184.nip.io:8000/api/location-records';
    //'http://empresa1.192.168.0.184:8000/api/location-records';
    //'http://192.168.0.184:8000/api/location-records';

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
    final nombre = await SessionService.obtenerNombre();

    // NUEVO: Validar que el nombre no esté vacío.
    if (nombre == null || nombre.isEmpty) {
      _showError('No se pudo obtener el nombre del usuario');
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
      _sendRecordToServer(newRecord, nombre); // MODIFICADO: Pasamos el nombre.
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registro de Ubicación'),

        //backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        backgroundColor: const Color.fromARGB(255, 30, 38, 85),
        foregroundColor: Colors.white, //  Color del texto y los iconos
      ),
      backgroundColor: const Color.fromARGB(255, 11, 22, 37), // Color de fondo
      body: Column(
        children: [
          // --- NUEVO: Campo de texto para el nombre ---

          // --- Botón para registrar la ubicación ---
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: 250,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color.fromARGB(255, 19, 109, 19), // verde claro
                      Color.fromARGB(255, 13, 173, 125), // verde oscuro
                    ],
                  ),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: ElevatedButton.icon(
                  icon:
                      _isLoading
                          ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color.fromARGB(255, 240, 238, 238),
                            ),
                          )
                          : const Icon(Icons.location_on),
                  label: Text(
                    _isLoading ? 'Obteniendo...' : 'Registrar Asistencia',
                  ),
                  onPressed: _isLoading ? null : _getCurrentLocationAndRecord,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    textStyle: const TextStyle(fontSize: 16),
                    foregroundColor: const Color.fromARGB(255, 240, 236, 236),
                    backgroundColor: const Color.fromARGB(
                      0,
                      240,
                      234,
                      234,
                    ), // importante
                    shadowColor: Colors.transparent, // quitar sombra sólida
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 40),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Row(
                children: const [
                  Icon(
                    Icons.history, // ícono de flecha circular
                    color: Color.fromARGB(221, 245, 243, 243),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Historial de Registros',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 13),

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
                            horizontal: 8,
                            vertical: 4,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 4,

                          child: Ink(
                            decoration: const BoxDecoration(
                              borderRadius: BorderRadius.all(
                                Radius.circular(12),
                              ),
                              gradient: LinearGradient(
                                colors: [
                                  Color.fromARGB(255, 9, 12, 199),
                                  Color.fromARGB(255, 3, 172, 184), // inicio
                                  // fin
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: ListTile(
                              leading: const Icon(
                                Icons.pin_drop,
                                color: Color.fromARGB(255, 7, 231, 56),
                              ),
                              title: Text(
                                'Fecha: $formattedDate - Hora: $formattedTime',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              subtitle: Text(
                                'Lat: ${record.latitude.toStringAsFixed(4)}, Lon: ${record.longitude.toStringAsFixed(4)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
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
