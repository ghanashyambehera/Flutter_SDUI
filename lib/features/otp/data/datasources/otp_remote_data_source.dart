import 'package:dio/dio.dart';
import 'package:flutter_sdui/core/constants/api_paths.dart';
import 'package:flutter_sdui/core/network/dio_error_mapper.dart';

class OtpRemoteDataSource {
  OtpRemoteDataSource(this._dio);
  final Dio _dio;

  Future<Map<String, dynamic>> fetchScreen() async {
    try {
      final response = await _dio.get('${ApiPaths.sduiScreens}/otp');
      return Map<String, dynamic>.from(response.data as Map);
    } on DioException catch (e) {
      throw DioErrorMapper.toFailure(e);
    }
  }

  Future<Map<String, dynamic>> submit(Map<String, dynamic> body) async {
    try {
      final response =
          await _dio.post('${ApiPaths.sduiActions}/submit_otp', data: body);
      return Map<String, dynamic>.from(response.data as Map);
    } on DioException catch (e) {
      throw DioErrorMapper.toFailure(e);
    }
  }

  Future<Map<String, dynamic>> resend(Map<String, dynamic> body) async {
    try {
      final response =
          await _dio.post('${ApiPaths.sduiActions}/resend_otp', data: body);
      return Map<String, dynamic>.from(response.data as Map);
    } on DioException catch (e) {
      throw DioErrorMapper.toFailure(e);
    }
  }
}
