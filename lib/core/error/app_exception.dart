class AppException implements Exception {
  final String message;
  final String code;
  AppException(this.message, {this.code = 'UNKNOWN'});
  @override
  String toString() => message;
}

class NetworkException extends AppException {
  NetworkException(String message) : super(message, code: 'NETWORK_ERROR');
}

class AuthException extends AppException {
  AuthException(String message) : super(message, code: 'AUTH_ERROR');
}

class ForbiddenException extends AppException {
  ForbiddenException(String message) : super(message, code: 'FORBIDDEN');
}

class NotFoundException extends AppException {
  NotFoundException(String message) : super(message, code: 'NOT_FOUND');
}

class BadRequestException extends AppException {
  BadRequestException(String message) : super(message, code: 'BAD_REQUEST');
}

class ValidationException extends AppException {
  ValidationException(String message) : super(message, code: 'VALIDATION_ERROR');
}

class RateLimitException extends AppException {
  RateLimitException(String message) : super(message, code: 'RATE_LIMIT_EXCEEDED');
}

class ServerException extends AppException {
  ServerException(String message) : super(message, code: 'INTERNAL_ERROR');
}
