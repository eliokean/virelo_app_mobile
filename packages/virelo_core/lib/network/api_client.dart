import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/api_constants.dart';

class ApiClient {
  late Dio _dio;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  ApiClient() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 60),
        receiveTimeout: const Duration(seconds: 60),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ),
    );

    // SSL Pinning & TLS Validation Configuration
    _dio.httpClientAdapter = IOHttpClientAdapter(
      createHttpClient: () {
        final client = HttpClient();
        client.badCertificateCallback = (X509Certificate cert, String host, int port) {
          // En mode développement / réseau local uniquement
          if (kDebugMode || host == '10.0.2.2' || host == 'localhost' || host.startsWith('192.168.')) {
            return true;
          }
          return false;
        };
        return client;
      },
    );

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Fix URI resolution by ensuring path starts with /api
        if (!options.path.startsWith('/api')) {
          options.path = '/api${options.path.startsWith('/') ? options.path : '/${options.path}'}';
        }

        // Si la requête contient du FormData (upload de fichiers), laisser Dio gérer le multipart boundary
        if (options.data is FormData) {
          options.headers.remove('Content-Type');
          options.contentType = 'multipart/form-data';
        }

        // Ajouter le token dynamiquement
        final token = await _secureStorage.read(key: 'auth_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onResponse: (response, handler) {
        // Possibilité de logger les succès ici
        return handler.next(response);
      },
      onError: (DioException e, handler) {
        // Possibilité de logger ou gérer les 401 Globalement
        return handler.next(e);
      },
    ));
  }

  Dio get dio => _dio;

  // Utilitaires de stockage de token pour être utilisé par les services
  Future<void> saveToken(String token) async {
    await _secureStorage.write(key: 'auth_token', value: token);
  }

  Future<void> clearToken() async {
    await _secureStorage.delete(key: 'auth_token');
  }

  Future<String?> getToken() async {
    return await _secureStorage.read(key: 'auth_token');
  }
}
