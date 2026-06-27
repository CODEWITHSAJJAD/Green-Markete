import 'package:dio/dio.dart';
import '../error/app_exception.dart';

class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    AppException appException;
    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        appException = NetworkException('Connection timed out. Please try again.');
        break;
      case DioExceptionType.connectionError:
        appException = NetworkException('No internet connection.');
        break;
      case DioExceptionType.badResponse:
        final statusCode = err.response?.statusCode ?? 0;
        final body = err.response?.data;
        final message = body is Map ? (body['detail'] ?? 'Something went wrong') : 'Something went wrong';
        final code = body is Map ? (body['code'] ?? 'UNKNOWN') : 'UNKNOWN';
        switch (statusCode) {
          case 400:
            appException = BadRequestException(message.toString());
            break;
          case 401:
            appException = AuthException(message.toString());
            break;
          case 403:
            appException = ForbiddenException(message.toString());
            break;
          case 404:
            appException = NotFoundException(message.toString());
            break;
          case 422:
            appException = ValidationException(message.toString());
            break;
          case 429:
            appException = RateLimitException(message.toString());
            break;
          default:
            appException = ServerException(message.toString());
        }
        break;
      default:
        appException = NetworkException('An unexpected error occurred.');
    }
    handler.reject(DioException(
      requestOptions: err.requestOptions,
      error: appException,
      response: err.response,
      type: err.type,
    ));
  }
}
