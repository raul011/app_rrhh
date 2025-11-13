// lib/services/api_service.dart
import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart'; // 👈 agrega esto

class ApiService {
  // URL base de tu backend
  final String baseUrl;

  // Para dispositivos móviles usa tu IP local: 'http://192.168.1.100:3000/api'
  // Para producción: 'https://tudominio.com/api'

  // Constructor
  //ApiService({this.baseUrl = 'http://10.0.2.2:8000/api'});
  //ApiService({this.baseUrl = 'http://3.129.13.240:8000/api'});
  //ApiService({this.baseUrl = 'http://172.20.10.6:5000/api'});
  //ApiService({this.baseUrl = 'http://192.168.0.184:5000/api'});
  // ApiService({this.baseUrl = 'http://empresa1.192.168.0.184.nip.io:8000/api'});
  //ApiService({this.baseUrl = 'http://empresa1.172.20.10.6.nip.io:8000/api'});
  //ApiService({this.baseUrl = 'http://empresa1.192.168.43.184.nip.io:8000/api'});
  ApiService({this.baseUrl = 'http://empresa1.192.168.0.184.nip.io:8000/api'});
  //ApiService({this.baseUrl = 'http://empresa1.192.168.43.184.nip.io:8000/api'});
  static const Map<String, String> _defaultHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // Método para el login en Laravel Sanctum
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await post('/login', {
        'email': email,
        'password': password,
      });

      return response as Map<String, dynamic>;
    } catch (e) {
      rethrow; // Deja que la UI maneje el error
    }
  }

  // GET Request
  Future<dynamic> get(String endpoint) async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl$endpoint'), headers: _defaultHeaders)
          .timeout(const Duration(seconds: 15));

      return _handleResponse(response);
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      // Lanza una nueva excepción procesada solo para errores de red/timeout.
      throw _handleNetworkError(e);
    }
  }

  // POST Request
  Future<dynamic> post(String endpoint, Map<String, dynamic> data) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl$endpoint'),
            headers: _defaultHeaders,
            body: jsonEncode(data),
          )
          .timeout(const Duration(seconds: 15));

      return _handleResponse(response);
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      // Lanza una nueva excepción procesada solo para errores de red/timeout.
      throw _handleNetworkError(e);
    }
  }

  // PUT Request
  Future<dynamic> put(String endpoint, Map<String, dynamic> data) async {
    try {
      final response = await http
          .put(
            Uri.parse('$baseUrl$endpoint'),
            headers: _defaultHeaders,
            body: jsonEncode(data),
          )
          .timeout(const Duration(seconds: 15));

      return _handleResponse(response);
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      // Lanza una nueva excepción procesada solo para errores de red/timeout.
      throw _handleNetworkError(e);
    }
  }

  // PATCH Request
  Future<dynamic> patch(String endpoint, Map<String, dynamic> data) async {
    try {
      final response = await http
          .patch(
            Uri.parse('$baseUrl$endpoint'),
            headers: _defaultHeaders,
            body: jsonEncode(data),
          )
          .timeout(const Duration(seconds: 15));

      return _handleResponse(response);
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      // Lanza una nueva excepción procesada solo para errores de red/timeout.
      throw _handleNetworkError(e);
    }
  }

  // DELETE Request
  Future<dynamic> delete(String endpoint) async {
    try {
      final response = await http
          .delete(Uri.parse('$baseUrl$endpoint'), headers: _defaultHeaders)
          .timeout(const Duration(seconds: 15));

      return _handleResponse(response);
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      // Lanza una nueva excepción procesada solo para errores de red/timeout.
      throw _handleNetworkError(e);
    }
  }

  // Manejar respuesta HTTP
  dynamic _handleResponse(http.Response response) {
    switch (response.statusCode) {
      case 200:
      case 201:
      case 202:
        if (response.body.isEmpty) {
          return {'success': true};
        }
        return jsonDecode(response.body);
      case 400:
        throw ApiException('Petición incorrecta: ${response.body}');
      case 401:
        throw ApiException('No autorizado: Token inválido o expirado');
      case 403:
        throw ApiException('Prohibido: No tienes permisos');
      case 404:
        throw ApiException('No encontrado: El recurso no existe');
      case 500:
        throw ApiException('Error interno del servidor');
      default:
        throw ApiException(
          'Error HTTP ${response.statusCode}: ${response.body}',
        );
    }
  }

  // Manejar errores
  Never _handleNetworkError(dynamic error) {
    if (error is SocketException) {
      throw ApiException(
        'Sin conexión a internet. Por favor, revisa tu conexión.',
      );
    } else if (error is TimeoutException) {
      throw ApiException('El servidor tardó demasiado en responder.');
    } else {
      // Para cualquier otro tipo de error no esperado.
      throw ApiException('Ocurrió un error inesperado: ${error.toString()}');
    }
  }
}

// Clase de excepción personalizada para la API
class ApiException implements Exception {
  final String message;

  ApiException(this.message);

  @override
  String toString() => message;
}
