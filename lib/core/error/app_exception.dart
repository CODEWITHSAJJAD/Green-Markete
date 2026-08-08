class AppException implements Exception {
  final String message;
  final String? code;
  AppException(this.message, {this.code});
  @override
  String toString() => message;
}

class NetworkException extends AppException {
  NetworkException(super.message);
}

class AuthException extends AppException {
  AuthException(super.message);
}

class BadRequestException extends AppException {
  BadRequestException(super.message);
}

class ForbiddenException extends AppException {
  ForbiddenException(super.message);
}

class NotFoundException extends AppException {
  NotFoundException(super.message);
}

class ValidationException extends AppException {
  ValidationException(super.message);
}

class RateLimitException extends AppException {
  RateLimitException(super.message);
}

class ServerException extends AppException {
  ServerException(super.message);
}
