import 'dart:io';

import 'package:dio/dio.dart';

enum HTTPMethod { GET, POST, PUT, DELETE, PATCH, HEAD, OPTIONS }

class Request {
  final String url;
  late final HTTPMethod method;
  Map<String, String>? headers;
  dynamic body;

  Request({required this.url, required this.method, this.headers, this.body});
}

class Network {
  static String getBaseURL() {

    final baseUrl = Platform.isAndroid
        ? 'http://10.0.2.2:8000'
        : 'http://localhost:8000';


    //final baseUrl = 'https://nf0np0l7-3400.inc1.devtunnels.ms';
    return baseUrl;
  }

  final Dio dio = Dio();

  Network();

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
          throw APIExceptions(
            message: "Bad Response",
            type: APIExceptionType.badResponse,
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
