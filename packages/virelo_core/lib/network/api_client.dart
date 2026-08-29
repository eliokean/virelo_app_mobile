import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/api_constants.dart';

class ApiClient {
  late Dio _dio;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  // Empreintes SHA-256 du certificat backend de production (EXEMPLE)
  static const List<String> _pinnedFingerprints = [
    '3F:A3:8C:1E:5E:7B:9A:2F:1D:4C:6A:8B:0E:5D:7C:9F:3A:1B:2E:4D:6C:8A:0F:2E:4D:6C:8A:0F:2E:4D:6C:8A',
  ];

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

    // SSL Pinning Configuration
    _dio.httpClientAdapter = IOHttpClientAdapter(
      createHttpClient: () {
        final client = HttpClient();
        client.badCertificateCallback = (X509Certificate cert, String host, int port) {
          // AVERTISSEMENT : En mode développement local, on retourne TRUE pour accepter les certificats auto-signés
          // En PRODUCTION stricte (Niveau Bancaire), il FAUT vérifier l'empreinte :
          
          /*
          final String serverFingerprint = cert.sha256.replaceAll(':', '').toUpperCase();
          final String expectedFingerprint = _pinnedFingerprints.first.replaceAll(':', '').toUpperCase();
          return serverFingerprint == expectedFingerprint;
          */
          
          return true; // DÉSACTIVÉ POUR LE DÉVELOPPEMENT LOCAL
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
