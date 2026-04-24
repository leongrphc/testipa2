import 'package:dio/dio.dart';
import '../config/app_config.dart';
import '../supabase/supabase_provider.dart';

class ApiClient {
  ApiClient() : _dio = Dio(BaseOptions(baseUrl: AppConfig.apiBaseUrl));

  final Dio _dio;

  Future<Response<dynamic>> get(String path, {Map<String, dynamic>? queryParameters}) async {
    return _dio.get(path, queryParameters: queryParameters, options: await _authorizedOptions());
  }

  Future<Response<dynamic>> post(String path, {Object? data, Map<String, dynamic>? queryParameters}) async {
    return _dio.post(path, data: data, queryParameters: queryParameters, options: await _authorizedOptions());
  }

  Future<Response<dynamic>> patch(String path, {Object? data}) async {
    return _dio.patch(path, data: data, options: await _authorizedOptions());
  }

  Future<Options> _authorizedOptions() async {
    final token = supabaseClient.auth.currentSession?.accessToken;
    return Options(headers: {
      if (token != null) 'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    });
  }
}

final apiClient = ApiClient();
