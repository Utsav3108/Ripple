import 'dart:io';

import 'package:dio/dio.dart';
import '../core/config/app_config.dart';

enum HTTPMethod { GET, POST, PUT, DELETE, PATCH, HEAD, OPTIONS }

class Request {
  final String url;
  late final HTTPMethod method;
  Map<String, String>? headers;
  dynamic body;

  Request({required this.url, required this.method, this.headers, this.body});
}

class Network {
  static final Network _instance = Network._internal();
  factory Network() => _instance;

  final Dio dio = Dio();
  String? _token;

  Network._internal();

  void setToken(String token) {
    _token = token;
    dio.options.headers['Authorization'] = 'Bearer $token';
  }

  void clearToken() {
    _token = null;
    dio.options.headers.remove('Authorization');
  }

  static String getBaseURL() {
    return Platform.isAndroid
        ? AppConfig.androidBaseUrl
        : AppConfig.iosBaseUrl;
  }

  Future<Response> performRequest(Request request) async {
    try {
      final response = await send(request: request);

      _log(request, response);

      _validate(response);

      return response;
    } on DioException catch (e) {
      switch (e.type) {
        case DioExceptionType.connectionError:
          print("Well, Server is under maintenance.");
          throw APIExceptions(
            message: "Well, Server is under maintenance.",
            type: APIExceptionType.ServerUnderMaintenance,
          );
        case DioExceptionType.badResponse:
          final responseData = e.response?.data;
          String errorMsg = "Bad Response";
          if (responseData is Map && responseData.containsKey('detail')) {
            errorMsg = responseData['detail'].toString();
          } else if (responseData is Map && responseData.containsKey('message')) {
            errorMsg = responseData['message'].toString();
          } else if (e.response?.statusMessage != null) {
            errorMsg = e.response!.statusMessage!;
          }
          throw APIExceptions(
            message: errorMsg,
            type: APIExceptionType.badResponse,
            statusCode: e.response?.statusCode,
          );
        case DioExceptionType.connectionTimeout:
          throw Exception("Connection Timeout");
        default:
          print(e);
          throw Exception(e.toString());
      }
    }
  }

  _log(Request request, Response res) {
    print("Response for ${request.url}");
    print("body: ${request.body}");
    print(res.data);
  }

  _validate(Response res) {
    if (res.statusCode == 200) {
      return true;
    } else if (res.data is Map<String, dynamic>) {
      if (res.data["status"] == 403) {
        throw APIExceptions(
          message: res.data["message"],
          statusCode: res.data["status"] as int,
        );
      } else if (res.data["status"] == 500) {
        throw APIExceptions(
          message: "Server is under maintenance..",
          statusCode: res.data["status"] as int,
        );
      }
    }
    return false;
  }

  Future<Response> send({required Request request}) {
    switch (request.method) {
      case HTTPMethod.GET:
        return dio.get(
          createURL(endpoint: request.url),
          queryParameters: request.body is Map<String, dynamic> ? request.body : null,
        );
      case HTTPMethod.POST:
        return dio.post(createURL(endpoint: request.url), data: request.body);
      case HTTPMethod.PUT:
        return dio.put(createURL(endpoint: request.url), data: request.body);
      case HTTPMethod.DELETE:
        return dio.delete(createURL(endpoint: request.url), data: request.body);
      case HTTPMethod.PATCH:
        return dio.patch(createURL(endpoint: request.url), data: request.body);
      default:
        throw Exception("Invalid HTTP method");
    }
  }

  String createURL({required String endpoint}) {
    return Network.getBaseURL() + endpoint;
  }
}

// ===== API Exceptions ====

enum APIExceptionType {
  ServerUnderMaintenance,
  badResponse,
  noInternet,
  unAuthorised,
}

class APIExceptions implements Exception {
  final String message;
  final APIExceptionType? type;
  final int? statusCode;

  APIExceptions({required this.message, this.type, this.statusCode});

  @override
  String toString() => message;
}
