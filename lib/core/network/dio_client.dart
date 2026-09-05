import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gaweflutter/core/config/app_config.dart';
import 'package:gaweflutter/core/constants/app_constants.dart';
import 'package:gaweflutter/core/storage/secure_storage.dart';
import 'package:gaweflutter/features/auth/presentation/providers/auth_provider.dart';

class DioClient {
  final Dio _dio;
  final Ref _ref;

  DioClient(this._ref)
      : _dio = Dio(
          BaseOptions(
            connectTimeout: AppConstants.connectTimeout,
            receiveTimeout: AppConstants.receiveTimeout,
            contentType: Headers.jsonContentType,
            responseType: ResponseType.json,
            headers: {
              'Accept': 'application/json',
            },
          ),
        ) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Dynamically resolve base URL from AppConfig (whether from .env or SecureStorage)
          final currentBaseUrl = await AppConfig.getBaseUrl();
          if (currentBaseUrl != null && currentBaseUrl.isNotEmpty) {
            options.baseUrl = currentBaseUrl;
          }

          // Retrieve bearer token from secure storage
          final token = await SecureStorage.getToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          
          if (kDebugMode) {
            print('--> ${options.method} ${options.uri}');
            print('Headers: ${options.headers}');
            print('Data: ${options.data}');
          }
          return handler.next(options);
        },
        onResponse: (response, handler) {
          if (kDebugMode) {
            print('<-- ${response.statusCode} ${response.requestOptions.uri}');
            print('Response Data: ${response.data}');
          }
          return handler.next(response);
        },
        onError: (DioException e, handler) {
          if (e.response?.statusCode == 401) {
            // Token invalid or expired, force logout
            // Avoid infinite loop if the failed request itself is logout
            final requestPath = e.requestOptions.path;
            if (requestPath != '/logout') {
              _ref.read(authProvider.notifier).logout();
            }
          }
          if (kDebugMode) {
            print('<-- ERROR: ${e.message}');
            print('Error Response: ${e.response?.data}');
          }
          return handler.next(e);
        },
      ),
    );
  }

  Dio get dio => _dio;
}

final dioClientProvider = Provider<DioClient>((ref) => DioClient(ref));
final dioProvider = Provider<Dio>((ref) => ref.watch(dioClientProvider).dio);

