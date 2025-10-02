import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

final myDio = Dio(
  BaseOptions(
    baseUrl:
        dotenv.env['SERVER_URL'] ?? 'https://20e432bff7c6.ngrok-free.app/api',
    connectTimeout: Duration(seconds: 5),
    receiveTimeout: Duration(seconds: 3),
  ),
);
